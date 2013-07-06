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

//TODO: un-singleton-ify this to ensure multi-user compatibility
class User {
	/** The user's id */
	private static int64 id;
	/** screen_name, unique per user, e.g. baedert(always written as @baedert) */
	public static string screen_name;
	/** Normal name like 'Chuck Norris' */
	public static string name;
	private static string avatar_name = "no_profile_pic.png";
	public static string avatar_url;


	public static string get_avatar_path(){
		return Utils.user_file("assets/user/"+avatar_name);
	}


	/**
	 * Loads the user's cached data from the database.
	 */
	public static void load(){
		try{
			SQLHeavy.Query query = new SQLHeavy.Query(Corebird.db,
				"SELECT screen_name, avatar_name, avatar_url, id FROM `user`;");
			SQLHeavy.QueryResult res = query.execute();
			User.screen_name = res.fetch_string(0);
			User.avatar_name = res.fetch_string(1);
			User.avatar_url  = res.fetch_string(2);
			User.id          = res.fetch_int64(3);
		}catch(SQLHeavy.Error e){
			error("Error while loading the user: %s", e.message);
		}
	}

// TODO: Check who the user follows, etc. to builid a cache and give the user
// auto-completion when composing a tweet

	/**
	 * Simply returns the id of the user.
	 *
	 * @return The user's ID.
	 */
	public static int64 get_id(){
		return id;
	}
}
