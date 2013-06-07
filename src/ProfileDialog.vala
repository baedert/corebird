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
using Gtk;


/**
 * A Dialog showing information about the given user.
 */
class ProfileDialog : Gtk.Window {
	private ProfileWidget profile_widget;

	public ProfileDialog(int64 user_id = 0){
		if (user_id <= 0)
			user_id = User.get_id();
		message(@"ID: $user_id");

		profile_widget = new ProfileWidget(null);
		profile_widget.set_user_id(user_id);

		this.resize(320, 480);
		this.add(profile_widget);
	}
}
