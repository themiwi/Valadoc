/* taglet.vala
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
 * 	Didier 'Ptitjes Villevalois <ptitjes@free.fr>
 */

using Gee;


public abstract class Valadoc.Content.InlineTaglet : ContentElement, Taglet, Inline {
	protected Settings settings;
	protected ResourceLocator locator;
	private ContentElement _content;

	public InlineTaglet () {
		base ();
	}

	public abstract Rule? get_parser_rule (Rule run_rule);

	public abstract void xml_importer_parer_rule (Xml.DocumentationImporter importer);

	public abstract ContentElement produce_content ();

	private ContentElement get_content () {
		if (_content == null) {
			_content = produce_content ();
		}
		return _content;
	}

	public override void configure (Settings settings, ResourceLocator locator) {
		this.settings = settings;
		this.locator = locator;
	}

	public override void check (Api.Tree api_root, Api.Node container, ErrorReporter reporter, Settings settings) {
		ContentElement element = get_content ();
		element.check (api_root, container, reporter, settings);
	}

	public override void accept (ContentVisitor visitor) {
		ContentElement element = get_content ();
		element.accept (visitor);
	}
}

