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



class IntHistory {
  private int[] elements;
  private int pos = -1;

  public int current {
    get{ if (pos==-1)return -1; return elements[pos];}
  }


  public IntHistory (int size) {
    elements = new int[size];
    for (int i = 0; i < size; i++)
      elements[i] = -1;
  }

  public void push (int v) {
    if (pos < elements.length - 1) {
      pos ++;
      elements[pos] = v;
    } else {
      for (int i = 1; i < elements.length; i++)
        elements[i-1] = elements[i];
      elements[pos] = v;
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

/*  public void print () {
    string a = "[";
    for (int i = 0; i < elements.length; i++)
      if (i == pos)
        a += "*"+elements[i].to_string ()+"*,";
      else
        a += elements[i].to_string ()+",";
    a += "]";
    message (a);
  }*/
}
