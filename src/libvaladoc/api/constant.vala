/* constant.vala
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
using Valadoc.Content;

public class Valadoc.Api.Constant : Member {
	public TypeReference type_reference { private set; get; }

	public Constant (Vala.Constant symbol, Node parent) {
		base (symbol, parent);
		type_reference = new TypeReference (symbol.type_reference, this);
	}

	public string get_cname () {
		return ((Vala.Constant) symbol).get_cname ();
	}

	internal override void resolve_type_references (Tree root) {
		type_reference.resolve_type_references (root);
	}

	protected override Inline build_signature () {
		return new SignatureBuilder ()
			.append_keyword (get_accessibility_modifier ())
			.append_keyword ("const")
			.append_content (type_reference.signature)
			.append_symbol (this)
			.get ();
	}

	public override NodeType node_type { get { return NodeType.CONSTANT; } }

	public override void accept (Visitor visitor) {
		visitor.visit_constant (this);
	}
}

