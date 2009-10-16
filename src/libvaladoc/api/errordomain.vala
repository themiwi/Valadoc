/*
 * Valadoc.Api.- a documentation tool for vala.
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

using Gee;
using Valadoc.Content;


public class Valadoc.Api.ErrorDomain : TypeSymbol, MethodHandler {
	private Vala.ErrorDomain verrdom;

	public ErrorDomain (Vala.ErrorDomain symbol, Node parent) {
		base (symbol, parent);
		this.verrdom = symbol;
	}

	public string? get_cname () {
		return this.verrdom.get_cname();
	}

	public void visit_error_codes (Doclet doclet) {
		accept_children_by_type (NodeType.ERROR_CODE, doclet);
	}

	public Collection<ErrorCode> get_error_code_list () {
		return get_children_by_type (NodeType.ERROR_CODE);
	}

	public void visit (Doclet doclet) {
		doclet.visit_error_domain (this);
	}

	public override NodeType node_type { get { return NodeType.ERROR_DOMAIN; } }

	public override void accept (Doclet doclet) {
		visit (doclet);
	}

	protected override Inline build_signature () {
		return new SignatureBuilder ()
			.append_keyword (get_accessibility_modifier ())
			.append_keyword ("errordomain")
			.append_symbol (this)
			.get ();
	}
}