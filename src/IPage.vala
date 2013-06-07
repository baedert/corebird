/*  This file is part of corebird.
 *
 *  Foobar is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Foobar is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */

interface IPage : Gtk.Widget {
	public abstract void on_join(int page_id, va_list arg_list);
	public abstract void create_tool_button(Gtk.RadioToolButton? group);
	public abstract int get_id();
	public abstract Gtk.RadioToolButton? get_tool_button();
	public abstract int unread_count{get;set;}
}
