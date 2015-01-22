/*  This file is part of corebird, a Gtk+ linux Twitter client.
 *  Copyright (C) 2013 Timm Bäder
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



public class BundleHistory {
  private int[] elements;
  private Bundle[] bundles;
  private int pos = -1;

  public int current {
    get {
      if (pos == -1)
        return -1;

      return elements[pos];
    }
  }

  public Bundle? current_bundle {
    get {
      if (pos == -1)
        return null;

      return bundles[pos];
    }
  }


  public BundleHistory (int size) {
    elements = new int[size];
    for (int i = 0; i < size; i++)
      elements[i] = -1;

    bundles = new Bundle[size];
  }

  public void push (int v, Bundle? b) {
    if (pos < elements.length - 1) {
      pos ++;
      elements[pos] = v;
      bundles[pos] = b;
    } else {
      for (int i = 1; i < elements.length; i++) {
        elements[i-1] = elements[i];
        bundles[i-1] = bundles[i];
      }
      elements[pos] = v;
      bundles[pos] = b;
    }
  }

  public int back () {
    if (pos > 0) {
      pos--;
      return elements[pos];
    }
    return -1;
  }

  public int forward () {
    if (pos < elements.length - 1) {
      pos ++;
      return elements[pos];
    }
    return -1;
  }

  public bool at_start () {
    return pos == 0;
  }

  public bool at_end () {
    if (pos == elements.length -1)
      return true;

    if (elements[pos] == -1 ||
        elements[pos + 1] == -1)
      return true;

    return false;
  }

  public string to_string () {
    string a = "[";
    for (int i = 0; i < elements.length; i++) {
      string bundle_str = bundles[i] != null ? bundles[i].to_string () : "";
      if (i == pos)
        a += "*"+elements[i].to_string ()+"*(" + bundle_str + "),";
      else
        a += elements[i].to_string ()+"(" + bundle_str + "),";
    }
    a += "]";
    return a;
  }
}
