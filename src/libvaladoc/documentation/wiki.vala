/* wiki.vala
 *
 * Copyright (C) 2008-2009 Florian Brosch
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

public class Valadoc.WikiPage : Object, Documentation {
	public Content.Page documentation {
		protected set;
		get;
	}

	public string documentation_str {
		private set;
		get;
	}

	public string path {
		private set;
		get;
	}

	public string name {
		private set;
		get;
	}


	public Api.Package? package {
		get {
			return _package;
		}
	}

	private Api.Package _package;

	public string? get_filename () {
		return Path.get_basename(this.path);
	}

	public WikiPage (string name, string path, Api.Package package) {
		this._package = package;
		this.name = name;
		this.path = path;
	}

	public void read () throws GLib.FileError {
		try {
			string content;
			FileUtils.get_contents (this.path, out content);
			this.documentation_str = content;
		} catch (FileError err) {
			throw err;
		}
	}

	public bool parse (DocumentationParser docparser, Api.Package pkg) {
		documentation = docparser.parse_wikipage (this, pkg);
		return true;
	}
}


public class Valadoc.WikiPageTree : Object {
	private ArrayList<WikiPage> wikipages;
	private ErrorReporter reporter;
	private Settings settings;

	//TODO: reporter, settings -> create_tree
	public WikiPageTree (ErrorReporter reporter, Settings settings) {
		this.reporter = reporter;
		this.settings = settings;
	}

	public Collection<WikiPage> get_pages () {
		return this.wikipages == null? Collection.empty<WikiPage> () : this.wikipages.read_only_view;
	}

	public WikiPage? search (string name) {
		if (this.wikipages == null) {
			return null;
		}

		foreach (WikiPage page in this.wikipages ) {
			if (page.name == name) {
				return page;
			}
		}
		return null;
	}

	private void create_tree_from_path (DocumentationParser docparser, Api.Package package, string path, string? nameoffset = null) throws GLib.FileError {
		Dir dir = Dir.open (path);

		for (string? curname = dir.read_name (); curname!=null ; curname = dir.read_name ()) {
			string filename = Path.build_filename (path, curname);
			if (curname.has_suffix (".valadoc") && FileUtils.test (filename, FileTest.IS_REGULAR)) {
				WikiPage wikipage = new WikiPage ((nameoffset!=null)? Path.build_filename (nameoffset, curname) : curname, filename, package);
				this.wikipages.add(wikipage);
				wikipage.read ();
			} else if (FileUtils.test (filename, FileTest.IS_DIR)) {
				this.create_tree_from_path (docparser, package, filename, (nameoffset!=null)? Path.build_filename (nameoffset, curname) : curname);
			}
		}
	}

	public void create_tree (DocumentationParser docparser, Api.Package package) throws GLib.FileError {
		try {
			weak string path = this.settings.wiki_directory;
			if (path == null) {
				return ;
			}

			this.wikipages = new ArrayList<WikiPage> ();
			this.create_tree_from_path (docparser, package, path);

			foreach (WikiPage page in this.wikipages) {
				page.parse (docparser, package);
			}
		} catch (FileError err) {
			throw err;
		}
	}
}


