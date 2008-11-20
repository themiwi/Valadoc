/*
 * Valadoc - a documentation tool for vala.
 * Copyright (C) 2008 Florian Brosch
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using Valadoc;
using Config;
using GLib;
using Vala;
using Gee;







public class ValaDoc : Object {
	private static string basedir = null;
	private static string directory = null;
	private static string pkg_name = null;
	private static string pkg_version = null;

	private static bool add_inherited = false;
	private static bool _protected = false;
	private static bool with_deps = false;
	private static bool _private = false;
	private static bool version;

	private static string pluginpath;

	private static bool non_null_experimental = false;
	private static bool disable_non_null = false;
	private static bool disable_checking;
	private static bool force = false;


	[NoArrayLength ()]
	private static string[] vapi_directories;
	[NoArrayLength ()]
	private static weak string[] tsources;
	[NoArrayLength ()]
	private static weak string[] tpackages;


	private Module docletmodule;
	private Type doclettype;


	private Gee.ArrayList<string> packages = new Gee.ArrayList<string>(); // remove
	private Gee.ArrayList<string> sources  = new Gee.ArrayList<string>(); // remove


	private const GLib.OptionEntry[] options = {
		{ "vapidir", 0, 0, OptionArg.FILENAME_ARRAY, out vapi_directories,
			"Look for package bindings in DIRECTORY", "DIRECTORY..." },
		{ "pkg", 0, 0, OptionArg.STRING_ARRAY, out tpackages, "Include binding for PACKAGE", "PACKAGE..." },
		//{ "library", 0, 0, OptionArg.STRING, out library, "Library name", "NAME" },
		//{ "basedir", 'b', 0, OptionArg.FILENAME, out basedir, "Base source directory", "DIRECTORY" },
		{ "directory", 'o', 0, OptionArg.FILENAME, out directory, "Output directory", "DIRECTORY" },
//		{ "package-name", 0, 0, OptionArg.FILENAME, out package_name, "Package name", "DIRECTORY" },
		{ "protected", 0, 0, OptionArg.NONE, ref _protected, "Adds protected elements to documentation", null },
		{ "private", 0, 0, OptionArg.NONE, ref _private, "Adds private elements to documentation", null },
		{ "inherit", 0, 0, OptionArg.NONE, ref add_inherited, "Adds inherited elements to a class", null },
//		{ "extend", 0, 0, OptionArg.NONE, ref add_documentation, "Adds documentation to a given directory", null },
		{ "deps", 0, 0, OptionArg.NONE, ref with_deps, "Adds packages to the documentation", null },
		{ "disable-non-null", 0, 0, OptionArg.NONE, ref disable_non_null, "Disable non-null types", null },
		{ "enable-non-null-experimental", 0, 0, OptionArg.NONE, ref non_null_experimental,
				"Enable experimentalenhancements for non-null types", null },
		{ "", 0, 0, OptionArg.FILENAME_ARRAY, out tsources, null, "FILE..." },
		{ "doclet", 0, 0, OptionArg.FILENAME, ref pluginpath, "plugin", "DIRECTORY" },
		{ "package-name", 0, 0, OptionArg.STRING, ref pkg_name, "package name", "DIRECTORY" },
		{ "package-version", 0, 0, OptionArg.STRING, ref pkg_version, "package version", "DIRECTORY" },
//		{ "xml", 0, 0, OptionArg.FILENAME, ref xmlsource, "xml", "DIRECTORY" },
		{ "force", 0, 0, OptionArg.NONE, ref force, "force", null },
		{ null }
	};

	private static int quit () {
		if (Report.get_errors () == 0) {
			stdout.printf ("Succeeded - %d warning(s)\n", Report.get_warnings ());
			return 0;
		}
		else {
			stdout.printf ("Failed: %d error(s), %d warning(s)\n", Report.get_errors (), Report.get_warnings ());
			return 1;
		}
	}
/*
	private bool add_package (CodeContext context, string pkg) {
		if (context.has_package (pkg)) {
			// ignore multiple occurences of the same package
			return true;
		}
	
		var package_path = context.get_package_path (pkg, vapi_directories);
		
		if (package_path == null) {
			return false;
		}
	
		context.add_package (pkg);
		
		context.add_source_file (new SourceFile (context, package_path, true));
		
		var deps_filename = Path.build_filename (Path.get_dirname (package_path), "%s.deps".printf (pkg));
		if (FileUtils.test (deps_filename, FileTest.EXISTS)) {
			try {
				string deps_content;
				ulong deps_len;
				FileUtils.get_contents (deps_filename, out deps_content, out deps_len);
				foreach (string dep in deps_content.split ("\n")) {
					if (dep != "") {
						if (!add_package (context, dep)) {
							Report.error (null, "%s, dependency of %s, not found in specified Vala API directories".printf (dep, pkg));
						}
					}
				}
			} catch (FileError e) {
				Report.error (null, "Unable to read dependency file: %s".printf (e.message));
			}
		}
		
		return true;
	}
*/
/*
	private string? get_package_path (string pkg) {
		if (FileUtils.test ( pkg, FileTest.EXISTS))
			return pkg;

		string basename = "%s.vapi".printf (pkg);

		if ( this.vapi_directories != null ) {
			foreach (string vapidir in this.vapi_directories ) {
				var filename = Path.build_filename (vapidir, basename);
				if (FileUtils.test (filename, FileTest.EXISTS)) {
					return filename;
				}
			}
		}

		string filename = Path.build_filename ("/usr/local/share/vala/vapi", basename);
		if (FileUtils.test (filename, FileTest.EXISTS)) {
			return filename;
		}

		filename = Path.build_filename ("/usr/share/vala/vapi", basename);
		if (FileUtils.test (filename, FileTest.EXISTS)) {
			return filename;
		}
		return null;
	}
*/
	private void add_files ( Vala.CodeContext context ) {
		foreach ( string source in this.sources ) {
			if (FileUtils.test (source, FileTest.EXISTS)) {
				var rpath = realpath (source);
				if (source.has_suffix (".vala") || source.has_suffix (".gs") ) {
					var source_file = new SourceFile (context, rpath, false);
					source_file.add_using_directive (new UsingDirective (new UnresolvedSymbol (null, "GLib", null)));
					context.add_source_file ( source_file );
				}
				else if (source.has_suffix (".vapi")) {
					context.add_source_file (new SourceFile (context, rpath, true));
				}
				else if (source.has_suffix (".c")) {
					context.add_c_source_file (rpath);
				}
				else {
					Report.error (null, "%s is not a supported source file type.".printf (source));
				}
			}
			else {
				Report.error (null, "%s not found".printf (source));
			}
		}
	}

	// remove
	private Gee.ArrayList<string> sort_sources ( ) {
		var to_doc = new Gee.ArrayList<string>();

		if ( tsources != null ) {
			foreach ( string str in this.tsources ) {
				string rpath = realpath ( str );
				if ( str.has_suffix ( ".vala" ) || str.has_suffix ( ".gs" ) )
					this.sources.add ( str );
				else
					this.packages.add ( str );

				to_doc.add ( rpath );
			}
		}

		if ( tpackages != null ) {
			foreach ( string str in this.tpackages ) {
				this.packages.add ( str );
			}
		}

		return to_doc;
	}

/*
	private static Gee.HashMap<string, Valadoc.TagletCreator> get_taglets ( ) {
		Gee.HashMap<string, Valadoc.TagletCreator> taglets
			= new Gee.HashMap<string, Valadoc.TagletCreator>(GLib.str_hash, GLib.str_equal);
		/*+
		void* function;
		Module module;
		GLib.Dir dir;

		string docletpath = realpath ( "plugins/html/taglets" );


		try {
			dir = GLib.Dir.open ( docletpath ); // throws FileError;
		}
		finally {
			stdout.printf ( "Can't load plugin.\n" );
		}

		for ( weak string entry = dir.read_name(); entry != null ; entry = dir.read_name() ) {
			if ( !( entry.has_suffix(".so") || entry.has_suffix(".dll") ) )
				continue ;

			string tagletpath = docletpath + "/" + entry;

			module = Module.open ( tagletpath, ModuleFlags.BIND_LAZY);
			if (module == null) {
				stdout.printf ( "Can't load plugin.\n" );
				return taglets;
			}

			module.symbol( "register_plugin", out function );
			Valadoc.TagletRegisterFunction tagletregisterfkt = (Valadoc.TagletRegisterFunction) function;

			
			//Valadoc.TagletCreator creator;
			//string name;

			//Type type = tagletregisterfkt ( out name, out creator );
			

			Type type = tagletregisterfkt ( taglets );
		}

			+/

		/+
		entries.set ( "", (Valadoc.TagletCreator)Valadoc.GlobalTaglet.create );
		entries.set ( "see", (Valadoc.TagletCreator)Valadoc.SeeTaglet.create );
		entries.set ( "link", (Valadoc.TagletCreator)Valadoc.LinkTaglet.create );
		entries.set ( "param", (Valadoc.TagletCreator)Valadoc.ParameterTaglet.create );
		entries.set ( "return", (Valadoc.TagletCreator)Valadoc.ReturnTaglet.create );
		entries.set ( "throws", (Valadoc.TagletCreator)Valadoc.ExceptionTaglet.create );
		+/
		return taglets;
	}
*/
	private bool check_doclet_structure ( string realpath ) {
		bool tmp = FileUtils.test ( realpath, FileTest.IS_DIR );
		if ( tmp == false ) {
			return false;
		}

		tmp = FileUtils.test ( realpath + "/libdoclet.so", FileTest.IS_EXECUTABLE );
		if ( tmp == false ) {
			return false;
		}


		tmp = FileUtils.test ( realpath + "/taglets/", FileTest.IS_DIR );
		if ( tmp == false ) {
			return false;
		}

		return true;
	}

	private bool load_taglets ( string fulldirpath, out Gee.HashMap<string, Type>? taglets2, out Type strtag ) {
		void* function;
		GLib.Dir dir;

		string pluginpath = fulldirpath + "taglets/";

		Gee.ArrayList<Module*> modules = new Gee.ArrayList<weak Module*> ( );


//		Gee.HashMap<string, Type> taglets =
			taglets2 = new Gee.HashMap<string, Type> ( GLib.str_hash, GLib.str_equal );

		try {
			dir = GLib.Dir.open ( pluginpath );
		}
		catch ( FileError err ) {
			stdout.printf ( "Can't load plugin. %s\n", pluginpath );
			taglets2 = null;
			return false;
		}

		for ( weak string entry = dir.read_name(); entry != null ; entry = dir.read_name() ) {
			if ( !( entry.has_suffix(".so") || entry.has_suffix(".dll") ) )
				continue ;

			string tagletpath = pluginpath + "/" + entry;

			Module* module = Module.open ( tagletpath, ModuleFlags.BIND_LAZY);
			if (module == null) {
				stdout.printf ( "Can't load plugin.\n" );
				taglets2 = null;
				return false;
			}

			module->symbol( "register_plugin", out function );
			Valadoc.TagletRegisterFunction tagletregisterfkt = (Valadoc.TagletRegisterFunction) function;


			GLib.Type type = tagletregisterfkt ( taglets2 );

			if ( entry == "libtagletstring.so" || entry == "libtagletstring.dll" )
				strtag = type;

			modules.add ( module );
		}

		return true;
	}

	private Doclet? load_doclet ( string path ) {
		void* function;

		docletmodule = Module.open ( path + "/libdoclet.so", ModuleFlags.BIND_LAZY);
		if (docletmodule == null) {
			return null;
		}

		docletmodule.symbol( "register_plugin", out function );
		if ( function == null ) {
			return null;
		}

		Valadoc.DocletRegisterFunction doclet_register_function = (Valadoc.DocletRegisterFunction) function;
		doclettype = doclet_register_function ( );
		return (Doclet)GLib.Object.new (doclettype);
	}

	private static bool check_pkg_name () {
		if ( pkg_name == null )
			return true;

		if ( pkg_name == "glib-2.0" || pkg_name == "gobject-2.0" )
			return false;

		foreach (string package in tsources ) {
			if ( pkg_name == package )
				return false;
		}
		return true;
	}

	private string get_pkg_name ( ) {
		if ( this.pkg_name == null ) {
			if ( this.directory.has_suffix ( "/" ) )
				this.pkg_name = GLib.Path.get_dirname ( this.directory );
			else
				this.pkg_name = GLib.Path.get_basename ( this.directory );
		}

		return this.pkg_name;
	}

	private int run (  ) {
		var settings = new Valadoc.Settings ( );
		settings.pkg_name = this.get_pkg_name ( );
		settings.pkg_version = this.pkg_version;

		settings.add_inherited = this.add_inherited;

		settings.files = this.sort_sources ( ); /// <--- remove!

		settings._protected = this._protected;
		settings.with_deps = this.with_deps;
		settings._private = this._private;
		settings.path = this.directory;


		Reporter reporter = new Reporter();

		string fulldirpath = (pluginpath == null)? Config.plugin_dir : pluginpath;
		bool tmp = this.check_doclet_structure ( pluginpath );

		if ( tmp == false ) {
			Report.error (null, "failed to load plugin" );
			return quit ();
		}


		Gee.HashMap<string, Type> taglets;
		GLib.Type strtag;

		tmp = this.load_taglets ( fulldirpath, out taglets, out strtag );
		if ( tmp == false ) {
			Report.error (null, "failed to load plugin" );
			return quit ();
		}

		Valadoc.Doclet doclet = this.load_doclet ( fulldirpath );
		if ( doclet == null ) {
			Report.error (null, "failed to load plugin" );
			return quit ();
		}

		Valadoc.Parser docparser = new Valadoc.Parser ();
		docparser.init ( settings, reporter, strtag, taglets );

		Valadoc.Tree doctree = new Valadoc.Tree ( settings, non_null_experimental, disable_non_null, disable_checking, basedir, directory );

		if (!doctree.add_external_package ( vapi_directories, "glib-2.0" )) {
			Report.error (null, "glib-2.0 not found in specified Vala API directories" );
			return quit ();
		}

		if (!doctree.add_external_package ( vapi_directories, "gobject-2.0" )) {
			Report.error (null, "gobject-2.0 not found in specified Vala API directories");
			return quit ();
		}

		if ( this.tpackages != null ) {
			foreach (string package in this.tpackages ) {
				if (!doctree.add_external_package ( vapi_directories, package )) {
					Report.error (null, "%s not found in specified Vala API directories".printf (package));
					return quit ();
				}
			}
			this.tpackages = null;
		}

		if ( this.tsources != null ) {
			foreach ( string src in this.tsources ) {
				stdout.printf ( ">__>%s\n", src );
				if ( !doctree.add_file ( src ) ) {
					Report.error (null, "%s not found".printf (src));
					return quit ();
				}
			}
			this.tsources = null;
		}

/*
		if ( this.sources != null ) {
			this.add_files( context );
			this.sources = null;
			if (Report.get_errors () > 0) {
				return quit ();
			}
		}
*/

		if ( !doctree.create_tree( ) )
			return quit ();

		doctree.parse_comments ( docparser );
		if ( reporter.errors > 0 )
			return 1;


		doclet.initialisation ( settings );

		doctree.visit ( doclet );

		doclet.cleanups ( );

		doclet = null;
		settings = null;
		doctree = null;
		return quit ();
	}

	private static bool remove_directory ( string rpath ) {
		try {
			GLib.Dir dir = GLib.Dir.open ( rpath ); //throws GLib.FileError
			if ( dir == null )
				return false;

			for ( weak string entry = dir.read_name(); entry != null ; entry = dir.read_name() ) {
				string path = rpath + entry;

				bool is_dir = GLib.FileUtils.test ( path, GLib.FileTest.IS_DIR );
				if ( is_dir == true ) {
					bool tmp = remove_directory ( path );
					if ( tmp == false ) {
						stderr.printf ( "Error: Can't remove directory %s.\n", path );
						return false;
					}
				}
				else {
					int tmp = GLib.FileUtils.unlink ( path );
					if ( tmp > 0 ) {
						stderr.printf ( "Error: Can't remove file %s.\n", path );
						return false;
					}
				}
			}
		}
		finally {}

		return true;
	}

	static int main ( string[] args ) {
		try {
			var opt_context = new OptionContext ("- Vala Documentation Tool");
			opt_context.set_help_enabled (true);
			opt_context.add_main_entries (options, null);
			opt_context.parse ( ref args);
		}
		catch (OptionError e) {
			stdout.printf ("%s\n", e.message);
			stdout.printf ("Run '%s --help' to see a full list of available command line options.\n", args[0]);
			return quit ();
		}

		if ( version ) {
			stdout.printf ("Valadoc %s\n", "0.1" );
			return 0;
		}

		if ( directory == null ) {
			Report.error (null, "No output directory specified." );
			return quit ();
		}

		if ( directory[ directory.len() - 1 ] != '/' ) {
			directory += "/";
		}

		if ( FileUtils.test ( directory, FileTest.EXISTS ) ) {
			if ( force == true ) {
				remove_directory ( directory );
			}
			else {
				Report.error (null, "File already exists." );
				return quit ();
			}
		}


		if ( pluginpath == null ) {
			pluginpath = Config.plugin_dir + "/template/";
		}
		else {
			if ( !pluginpath.has_suffix ( "/" ) )
				pluginpath = pluginpath + "/";
		}

		if ( !check_pkg_name () ) {
			Report.error (null, "Invalid package name." );
			return quit ();
		}

		var valadoc = new ValaDoc( );
		valadoc.run();
		return 0;
	}
}

