/* tagletinit.vala
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


namespace Valadoc.Taglets {
	public void init (ModuleLoader loader) {
		loader.taglets.set ("see", typeof (Valadoc.Taglets.See));
		loader.taglets.set ("since", typeof (Valadoc.Taglets.Since));
		loader.taglets.set ("link", typeof (Valadoc.Taglets.Link));
		loader.taglets.set ("throws", typeof (Valadoc.Taglets.Throws));
		loader.taglets.set ("return", typeof (Valadoc.Taglets.Return));
		loader.taglets.set ("param", typeof (Valadoc.Taglets.Param));
		loader.taglets.set ("deprecated", typeof (Valadoc.Taglets.Deprecated));
		loader.taglets.set ("inheritDoc", typeof (Valadoc.Taglets.InheritDoc));
	}
}
