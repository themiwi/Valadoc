/* resourcelocator.vala
 *
 * Copyright (C) 2008-2009 Florian Brosch, Didier Villevalois
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


public abstract class Valadoc.DocumentationImporter : Object, ResourceLocator {
	protected ErrorReporter errorreporter;
	protected ModuleLoader modules;
	protected Settings settings;
	protected Api.Tree tree;

	protected Content.ContentFactory factory;


	public DocumentationImporter (Api.Tree tree, ModuleLoader modules, Settings settings, ErrorReporter errorreporter) {
		factory = new Content.ContentFactory (settings, this, modules);

		this.errorreporter = errorreporter;
		this.settings = settings;
		this.modules = null;
		this.tree = tree;
	}

	public virtual string resolve (string path) {
		return path;
	}

	public abstract bool process (string filename, Settings settings, Api.Package package);
}


