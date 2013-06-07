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


public class Benchmark{
	private static GLib.Timer timer;
	private static string action_name;


	public static void start(string name){
		if(timer == null){
			timer = new GLib.Timer();
		}

		timer.start();
		action_name = name;
	}

	public static void stop(){
		timer.stop();
		ulong microseconds;
		timer.elapsed(out microseconds);
		float s = microseconds / 1000000.0f;
		message("%s took %fs", action_name, s);
	}


}