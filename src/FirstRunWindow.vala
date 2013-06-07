/*  This file is part of corebird.
 *
 *  corebird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  corebird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with corebird.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Rest;

// TODO: This sucks.
class FirstRunWindow : ApplicationWindow {
	private Box main_box;
	private Notebook nb;
	private Entry pin_entry;
	private Corebird app;

	public FirstRunWindow(Corebird app){
		GLib.Object(application: app);
		this.app = app;

		UIBuilder builder = new UIBuilder(DATADIR+"/ui/first-run-window.ui",
		                                  "main_box");
		this.main_box = builder.get_box("main_box");
		this.nb = builder.get_notebook("main_notebook");
		this.pin_entry = builder.get_entry("pin_entry");


		builder.get_button("cancel_button").clicked.connect(() => {
			this.destroy();
		});

		builder.get_button("next_button").clicked.connect(() => {
			int page = nb.get_current_page();
			message("Current Page: %d", page);

			switch(page){
				case 0:
					request_token();
				break;
				case 1:
					if(check_pin()){
						get_user_info();
					}
				break;

				default:
					error("WAT");
			}

			nb.next_page();
		});
		this.add(main_box);
		this.show_all();
	}

	private void switch_windows(){
		app.add_main_window();
		this.destroy();
	}

	private void request_token(){
    	GLib.Idle.add(() => {
			try{
				Twitter.proxy.request_token ("oauth/request_token", "oob");
				GLib.AppInfo.launch_default_for_uri(
					"http://twitter.com/oauth/authorize?oauth_token=%s"
	                                    .printf(Twitter.proxy.get_token()), null);
			}catch(GLib.Error e){
				critical("ERROR(request_token): %s", e.message);
			}
			return false;
		});
	}


	private bool check_pin() {
		try{
			Twitter.proxy.access_token("oauth/access_token", pin_entry.get_text());
		}catch(Error e){
			critical("Error while obtatning access token: %s", e.message);
			return false;
		}


		// Save token + token_secret
		try{
			Corebird.create_tables();
			//Write token + token_secret to the database
			SQLHeavy.Query q = new SQLHeavy.Query(Corebird.db, "INSERT INTO
			                  `common`(token, token_secret)
			                  VALUES (:t, :ts);");
			q.set_string(":t", Twitter.proxy.get_token());
			q.set_string(":ts", Twitter.proxy.get_token_secret());
			q.execute();
		}catch(SQLHeavy.Error e){
			error("SQL ERROR: "+e.message);
		}
		return true;
	}

	private void get_user_info(){
		var settings_call = Twitter.proxy.new_call();
		settings_call.set_function("1.1/account/settings.json");
		settings_call.set_method("GET");
		settings_call.invoke_async.begin(null, (obj, res) => {
			try{
				settings_call.invoke_async.end(res);
			} catch (GLib.Error e){
				error ("Error while ending settings_call: %s", e.message);
			}
			string back = settings_call.get_payload();
			var parser = new Json.Parser();
			try{
				parser.load_from_data(back);
			} catch(GLib.Error e){
				error("Error with Json data: %s\n DATA:\n%s", e.message, back);
			}

			var root           = parser.get_root().get_object();
			string screen_name = root.get_string_member("screen_name");
			try{
				SQLHeavy.Query screen_name_query = new SQLHeavy.Query(Corebird.db,
					@"INSERT INTO `user`(screen_name) VALUES ('$screen_name');");
				screen_name_query.execute();
			}catch(SQLHeavy.Error e){
				error("Error while settings the screen_name: %s", e.message);
			}

			// Now, get the user's other data
			User.screen_name = screen_name;
			User.load();
			User.update_info.begin(null, true, () => {
				switch_windows();
			});
			// TODO: If the User.update_info in the main window executes before this
			// call completed, the id will be 0 and a "not found" error will occure.

			// int64 id = User.id;
			// message(@"ID: $id");
			// Corebird.db.execute(@"UPDATE `user` SET `id`='$id' WHERE
			                    // `screen_name`='@screen_name'");
		});

	}

}
