
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
class TextButton : Button {

  public TextButton(string label=""){
    if(label != "")
      this.label= label;
    this.get_style_context().add_class("text-button");
  }


  /**
   * Adds a GtkLabel to the Button using the given text as markup.
   * If the button already contains another child, that will either be replaced if it's
   * no instance of GtkLabel, or - if it's a GtkLabel already - be reused.
   *
   * @param text The markup to use(see pango markup)
   */
  public void set_markup(string text) {
    Label label = null;
    Widget child = get_child();
    if(child != null){
      if(child is Label) {
        label = (Label)child;
        label.set_markup(text);
      }else{
        this.remove(child);
        label = new Label(text);
      }
    }else{
      label = new Label(text);
    }
    label.set_use_markup(true);
    label.set_justify(Justification.CENTER);

    label.visible = true;
    if(label.parent == null)
      this.add(label);
  }
}
