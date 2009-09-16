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


using Vala;
using GLib;
using Gee;


public class Valadoc.Array : Basic {
	private Vala.ArrayType vtype;

	public Basic data_type {
		private set;
		get;
	}

	public Array (Valadoc.Settings settings, Vala.ArrayType vtyperef, Basic parent, Tree head) {
		this.settings = settings;
		this.vtype = vtyperef;
		this.parent = parent;
		this.head = head;

		Vala.DataType vntype = vtyperef.element_type;
		if ( vntype is Vala.ArrayType )
			this.data_type = new Array (settings, (Vala.ArrayType)vntype, this, head);
		else
			this.data_type = new TypeReference (settings, vntype, this, head);
	}

	public void write (Langlet langlet, void* ptr, DocumentedElement parent) {
		langlet.write_array (this, ptr, parent);
	}

	public void set_type_references () {
		if ( this.data_type == null )
			/*TODO:possible?*/;
		else if ( this.data_type is Array )
			((Array)this.data_type).set_type_references ();
		else if ( this.data_type is Pointer )
			((Pointer)this.data_type).set_type_references ();
		else
			((TypeReference)this.data_type).set_type_references ();
	}
}
