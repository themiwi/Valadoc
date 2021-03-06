/* tree.vala
 *
 * Copyright (C) 2008  Florian Brosch
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Florian Brosch <flo.brosch@gmail.com>
 */

using Gee;

// private
public Valadoc.Api.Class glib_error = null;

public class Valadoc.Api.Tree {
	private ArrayList<Package> packages = new ArrayList<Package>();
	private Package source_package = null;
	private Settings settings;
	private Vala.CodeContext context;
	private ErrorReporter reporter;
	private Package sourcefiles = null;

	public WikiPageTree? wikitree {
		private set;
		get;
	}

	public Collection<Package> get_package_list () {
		return this.packages.read_only_view;
	}

	private void add_dependencies_to_source_package () {
		if ( this.source_package != null ) {
			ArrayList<Package> deplst = new ArrayList<Package> ();
			foreach (Package pkg in this.packages) {
				if (pkg != this.source_package) {
					deplst.add (pkg);
				}
			}
			this.source_package.set_dependency_list (deplst);
		}
	}

	public void accept (Visitor visitor) {
		visitor.visit_tree (this);
	}

	public void accept_children (Visitor visitor) {
		foreach (Node node in packages) {
			node.accept (visitor);
		}
	}

	private Node? search_relative_to (Node element, string[] path) {
		Api.Node? node = element;

		foreach (string name in path) {
			node = node.find_by_name (name);
			if (node == null) {
				break;
			}
		}

		if (node == null && element.parent != null) {
			node = search_relative_to ((Node) element.parent, path);
		}

		return node;
	}

	public Node? search_symbol_path (Node? element, string[] path) {
		Api.Node? node = null;

		// relative to element
		if (element != null) {
			node = search_relative_to (element, path);
			if (node != null) {
				return node;
			}
		}


		// absolute
		foreach (Package package in packages) {
			// search in root namespace
			node = search_relative_to (package.find_by_name (""), path);
			if (node != null) {
				return node;
			}
		}

		return null;
	}

	public Node? search_symbol_str (Node? element, string symname) {
		string[] path = split_name (symname);

		var node = search_symbol_path (element, path);
		if (node != null) {
			return node;
		}

		if (path.length >= 3 && path[path.length-3] == path[path.length-2]) {
			path[path.length-2] = path[path.length-2]+"."+path[path.length-1];
			path.resize (path.length-1);
			return search_symbol_path (element, path);
		}

		return null;
	}

	private string[] split_name (string full_name) {
		string[] params = (full_name).split (".", -1);
		int i = 0; while (params[i] != null) i++;
		params.length = i;
		return params;
	}

	public Tree (ErrorReporter reporter, Settings settings) {
		this.context = new Vala.CodeContext ( );
		Vala.CodeContext.push (context);

		this.settings = settings;
		this.reporter = reporter;

		reporter.vreporter = this.context.report;

		this.context.checking = settings.enable_checking;
		this.context.deprecated = settings.deprecated;
		this.context.experimental = settings.experimental;
		this.context.experimental_non_null = settings.experimental || settings.experimental_non_null;
		this.context.dbus_transformation = !settings.disable_dbus_transformation;


		if (settings.basedir == null) {
			context.basedir = realpath (".");
		} else {
			context.basedir = realpath (settings.basedir);
		}

		if (settings.directory != null) {
			context.directory = realpath (settings.directory);
		} else {
			context.directory = context.basedir;
		}

		if (settings.profile == "gobject-2.0" || settings.profile == "gobject" || settings.profile == null) {
			context.profile = Vala.Profile.GOBJECT;
			context.add_define ("GOBJECT");
		}

		if (settings.defines != null) {
			foreach (string define in settings.defines) {
				context.add_define (define);
			}
		}

		if (context.profile == Vala.Profile.POSIX) {
			/* default package */
			if (!add_package ("posix")) {
				Vala.Report.error (null, "posix not found in specified Vala API directories");
			}
		}
		else if (context.profile == Vala.Profile.GOBJECT) {
			int glib_major = 2;
			int glib_minor = 12;


			context.target_glib_major = glib_major;
			context.target_glib_minor = glib_minor;
			if (context.target_glib_major != 2) {
				Vala.Report.error (null, "This version of valac only supports GLib 2");
			}

			/* default packages */
			if (!this.add_package ("glib-2.0")) { //
				Vala.Report.error (null, "glib-2.0 not found in specified Vala API directories");
			}

			if (!this.add_package ("gobject-2.0")) { //
				Vala.Report.error (null, "gobject-2.0 not found in specified Vala API directories");
			}
		}
	}


	private bool add_package (string pkg) {
		if (context.has_package (pkg)) {
			// ignore multiple occurences of the same package
			return true;
		}

		var package_path = context.get_package_path (pkg, settings.vapi_directories);

		if (package_path == null) {
			return false;
		}

		context.add_package (pkg);


		var vfile = new Vala.SourceFile (context, package_path, true);
		context.add_source_file (vfile);

		Package vdpkg = new Package (vfile, pkg, true);
		this.packages.add (vdpkg);

		var deps_filename = Path.build_filename (Path.get_dirname (package_path), "%s.deps".printf (pkg));
		if (FileUtils.test (deps_filename, FileTest.EXISTS)) {
			try {
				string deps_content;
				ulong deps_len;
				FileUtils.get_contents (deps_filename, out deps_content, out deps_len);
				foreach (string dep in deps_content.split ("\n")) {
					dep.strip ();
					if (dep != "") {
						if (!add_package (dep)) {
							Vala.Report.error (null, "%s, dependency of %s, not found in specified Vala API directories".printf (dep, pkg));
						}
					}
				}
			} catch (FileError e) {
				Vala.Report.error (null, "Unable to read dependency file: %s".printf (e.message));
			}
		}

		return true;
	}

	// copied from valacodecontext.vala
	private string? get_file_path (string basename, string data_dir, string[] directories) {
		string filename = null;

		if (directories != null) {
			foreach (string dir in directories) {
				filename = Path.build_filename (dir, basename);
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					return filename;
				}
			}
		}

		foreach (string dir in Environment.get_system_data_dirs ()) {
			filename = Path.build_filename (dir, data_dir, basename);
			if (FileUtils.test (filename, FileTest.EXISTS)) {
				return filename;
			}
		}

		return null;
	}

	// copied from valacodecontext.vala
	private string? get_external_documentation_path (string pkg) {
		var path = get_file_path (Path.build_filename (pkg, pkg + ".valadoc"), "vala/vapi/documentation", settings.docu_directories);

		if (path == null) {
			/* last chance: try the package compiled-in vapi dir */
			var filename = Path.build_filename (Config.vapi_dir, "vapi", "documentation", pkg, pkg + ".valadoc");
			if (FileUtils.test (filename, FileTest.EXISTS)) {
				path = filename;
			}
		}

		return path;
	}

	public void add_depencies (string[] packages) {
		foreach (string package in packages) {
			if (!add_package (package)) {
				Vala.Report.error (null, "%s not found in specified Vala API directories".printf (package));
			}
		}
	}

	public void add_documented_file (string[] sources) {
		if (sources == null) {
			return;
		}

		foreach (string source in sources) {
			if (FileUtils.test (source, FileTest.EXISTS)) {
				var rpath = realpath (source);
				if (source.has_suffix (".vala") || source.has_suffix (".gs")) {
					var source_file = new Vala.SourceFile (context, rpath);


					if (this.sourcefiles == null) {
						this.sourcefiles = new Package (source_file, settings.pkg_name, false);
						this.packages.add (this.sourcefiles);
					} else {
						this.sourcefiles.add_file (source_file);
					}

					if (context.profile == Vala.Profile.POSIX) {
						// import the Posix namespace by default (namespace of backend-specific standard library)
						var ns_ref = new Vala.UsingDirective (new Vala.UnresolvedSymbol (null, "Posix", null));
						source_file.add_using_directive (ns_ref);
						context.root.add_using_directive (ns_ref);
					} else if (context.profile == Vala.Profile.GOBJECT) {
						// import the GLib namespace by default (namespace of backend-specific standard library)
						var ns_ref = new Vala.UsingDirective (new Vala.UnresolvedSymbol (null, "GLib", null));
						source_file.add_using_directive (ns_ref);
						context.root.add_using_directive (ns_ref);
					}

					context.add_source_file (source_file);
				} else if (source.has_suffix (".vapi")) {
					string file_name = Path.get_basename (source);
					file_name = file_name.ndup ( file_name.size() - ".vapi".size() );

					var vfile = new Vala.SourceFile (context, rpath, true);
					Package vdpkg = new Package (vfile, file_name);
					context.add_source_file (vfile);
					this.packages.add (vdpkg);
				} else if (source.has_suffix (".c")) {
					context.add_c_source_file (rpath);
				} else {
					Vala.Report.error (null, "%s is not a supported source file type. Only .vala, .vapi, .gs, and .c files are supported.".printf (source));
				}
			} else {
				Vala.Report.error (null, "%s not found".printf (source));
			}
		}
	}

	public bool create_tree ( ) {
		Vala.Parser parser = new Vala.Parser ();
		parser.parse (this.context);
		if (this.context.report.get_errors () > 0) {
			return false;
		}

		Vala.SymbolResolver resolver = new Vala.SymbolResolver ();
		resolver.resolve(this.context);
		if (this.context.report.get_errors () > 0) {
			return false;
		}

		Vala.SemanticAnalyzer analyzer = new Vala.SemanticAnalyzer ( );
		analyzer.analyze(this.context);
		if (this.context.report.get_errors () > 0) {
			return false;
		}

		Api.NodeBuilder builder = new NodeBuilder (this);
		this.context.accept(builder);
		this.resolve_type_references ();
		this.resolve_children ();
		this.add_dependencies_to_source_package ();
		return true;
	}

	private Package? find_package_for_file (Vala.SourceFile vfile) {
		foreach (Package pkg in this.packages) {
			if (pkg.is_package_for_file (vfile))
				return pkg;
		}
		return null;
	}

	private void resolve_type_references () {
		foreach (Package pkg in this.packages) {
			pkg.resolve_type_references (this);
		}
	}

	private void resolve_children () {
		foreach (Package pkg in packages) {
			pkg.resolve_children (this);
		}
	}

	private Package? get_source_package () {
		foreach (Package pkg in packages) {
			if (!pkg.is_package) {
				return pkg;
			}
		}

		return null;
	}

	private void process_wiki (DocumentationParser docparser) {
		this.wikitree = new WikiPageTree(this.reporter, this.settings);
		var pkg = get_source_package ();
		if (pkg != null) {
			wikitree.create_tree (docparser, pkg);
		}
	}

	// TODO Rename to process_comments
	public void parse_comments (DocumentationParser docparser) {
		// TODO Move Wiki tree parse to Package
		process_wiki (docparser);

		foreach (Package pkg in this.packages) {
			if (pkg.is_visitor_accessible (settings)) {
				pkg.process_comments(settings, docparser);
			}
		}
	}

	public void import_documentation (DocumentationImporter importer) {
		foreach (Package pkg in this.packages) {
			string? path = (pkg.is_package)? get_external_documentation_path (pkg.name) : null;

			if (pkg.is_visitor_accessible (settings) && path != null) {
				pkg.import_documentation (path, settings, importer);
			}
		}

	}

	internal Symbol? search_vala_symbol (Vala.Symbol symbol) {
		Vala.SourceFile source_file = symbol.source_reference.file;
		Package package = find_package_for_file (source_file);
		return search_vala_symbol_in (symbol, package);
	}

	internal Symbol? search_vala_symbol_in (Vala.Symbol symbol, Package package) {
		ArrayList<Vala.Symbol> params = new ArrayList<Vala.Symbol> ();
		for (Vala.Symbol iter = symbol; iter != null; iter = iter.parent_symbol) {
			if (iter is Vala.DataType) {
 				params.insert (0, ((Vala.DataType)iter).data_type);
			} else {
				params.insert (0, iter);
			}
		}

		if (params.size == 0) {
			return null;
		}

		Api.Node? node = package;
		foreach (Vala.Symbol a_symbol in params) {
			node = node.find_by_symbol (a_symbol);
			if (node == null) {
				return null;
			}
		}
		return (Symbol) node;
	}
}

