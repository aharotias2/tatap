/*
 *  Copyright 2019-2020 Tanaka Takayuki (田中喬之)
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Tanaka Takayuki <aharotias2@gmail.com>
 */

public class ActionButton : Gtk.Button {
    private string _icon_name;
    public string icon_name {
        get {
            return _icon_name;
        }
        set {
            _icon_name = value;
            image = new Gtk.Image.from_icon_name(_icon_name, Gtk.IconSize.SMALL_TOOLBAR);
        }
    }

    public ActionButton (string icon_name, string tooltip_text) {
        Object (
            icon_name: icon_name,
            tooltip_text: tooltip_text
        );
    }
}