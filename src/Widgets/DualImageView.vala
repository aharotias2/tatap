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

using Gdk, Gtk;

namespace Tatap {
    public class DualImageView : ImageView, Bin {
        public override ViewMode view_mode { get; construct; }
        public override Tatap.Window main_window { get; construct; }

        public override FileList file_list {
            get {
                return _file_list;
            }
            set {
                _file_list = value;
                _file_list.updated.connect(() => {
                    try {
                        accessor.set_file1(left_image.fileref);
                        main_window.image_next_button.sensitive = is_next_button_sensitive();
                        main_window.image_prev_button.sensitive = is_prev_button_sensitive();
                    } catch (Error e) {
                        file_list.close();
                    }
                });
                accessor = new DualFileAccessor.with_file_list(_file_list);
            }
        }

        public override string dir_path {
            owned get {
                return _file_list.dir_path;
            }
        }

        public override bool has_image {
            get {
                return left_image.has_image || right_image.has_image;
            }
        }

        private Box dual_box;
        private ScrolledWindow left_frame;
        private ScrolledWindow right_frame;
        private Image left_image;
        private Image right_image;
        private DualFileAccessor accessor;
        private FileList _file_list;

        private const string TITLE_FORMAT = "%s (%dx%d : %.2f%%), %s (%dx%d : %.2f%%)";

        public DualImageView(Window window) {
            Object(
                main_window: window,
                view_mode: ViewMode.DUAL_VIEW_MODE
            );
        }

        public DualImageView.with_file_list(Window window, FileList file_list) {
            Object(
                main_window: window,
                view_mode: ViewMode.DUAL_VIEW_MODE,
                file_list: file_list
            );
        }

        construct {
            var scroll = new ScrolledWindow(null, null);
            {
                dual_box = new Box(Orientation.HORIZONTAL, 0);
                {
                    left_frame = new ScrolledWindow(null, null);
                    {
                        left_image = new Image(true);
                        {
                            left_image.halign = Align.END;
                            left_image.container = left_frame;
                            left_image.get_style_context().add_class("image-view");
                        }

                        left_frame.add(left_image);
                    }

                    right_frame = new ScrolledWindow(null, null);
                    {
                        right_image = new Image(true);
                        {
                            right_image.halign = Align.START;
                            right_image.container = right_frame;
                            right_image.get_style_context().add_class("image-view");
                        }

                        right_frame.add(right_image);
                    }

                    dual_box.pack_start(left_frame, true, true);
                    dual_box.pack_start(right_frame, true, true);
                    dual_box.get_style_context().add_class("image-view");
                }

                scroll.add(dual_box);
                scroll.size_allocate.connect((allocation) => {
                    left_frame.width_request = allocation.width / 2;
                    left_frame.height_request = allocation.height;
                    left_image.fit_size_to_window();
                    right_frame.width_request = allocation.width / 2;
                    right_frame.height_request = allocation.height;
                    right_image.fit_size_to_window();
                    update_title();
                });
            }

            add(scroll);
            debug("Dual image view was created");
        }

        public File get_file() throws Error {
            return get_file1();
        }

        public File get_file1() throws AppError {
            return accessor.get_file1();
        }

        public File get_file2() throws AppError {
            return accessor.get_file2();
        }

        public bool is_next_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_last();
            } else {
                return !accessor.is_first();
            }
        }

        public bool is_prev_button_sensitive() {
            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                return !accessor.is_first();
            } else {
                return !accessor.is_last();
            }
        }

        public bool handle_event(Event ev) throws Error {
            switch (ev.type) {
              case EventType.SCROLL:
                if (ev.scroll.direction == ScrollDirection.UP) {
                    if (!accessor.is_first()) {
                        go_backward();
                    }
                } else if (ev.scroll.direction == ScrollDirection.DOWN) {
                    if (!accessor.is_last()) {
                        go_forward();
                    }
                }
                break;
              case EventType.KEY_PRESS:
                switch (ev.key.keyval) {
                  case Gdk.Key.Left:
                    if (left_image.has_image || right_image.has_image) {
                        if (main_window.toolbar.sort_order == SortOrder.ASC) {
                            if (!accessor.is_first()) {
                                go_backward();
                            }
                        } else {
                            if (!accessor.is_last()) {
                                go_forward();
                            }
                        }
                    }
                    return true;
                  case Gdk.Key.Right:
                    if (left_image.has_image || right_image.has_image) {
                        if (!accessor.is_last()) {
                            if (main_window.toolbar.sort_order == SortOrder.ASC) {
                                if (!accessor.is_last()) {
                                    go_forward();
                                }
                            } else {
                                if (!accessor.is_first()) {
                                    go_backward();
                                }
                            }
                        }
                    }
                    return true;
                }
                break;
              default:
                break;
            }
            return false;
        }

        public void go_forward(int offset = 1) throws Error {
            accessor.go_forward();
            open_by_accessor_current_index();
        }

        public void go_backward(int offset = 1) throws Error {
            accessor.go_backward();
            open_by_accessor_current_index();
        }

        private void open_by_accessor_current_index() throws Error {
            print("Open images at %d, %d\n", accessor.get_index1(), accessor.get_index2());
            if (accessor.first == 0) {
                if (main_window.toolbar.sort_order == SortOrder.ASC) {
                    if (accessor.get_index1() >= 0) {
                        left_image.visible = true;
                        left_image.open(accessor.get_file1().get_path());
                    } else {
                        left_image.visible = false;
                    }
                    if (accessor.get_index2() >= 0) {
                        right_image.visible = true;
                        right_image.open(accessor.get_file2().get_path());
                    } else {
                        right_image.visible = false;
                    }
                } else {
                    if (accessor.get_index1() >= 0) {
                        right_image.visible = true;
                        right_image.open(accessor.get_file1().get_path());
                    } else {
                        right_image.visible = false;
                    }
                    if (accessor.get_index2() >= 0) {
                        left_image.visible = true;
                        left_image.open(accessor.get_file2().get_path());
                    } else {
                        left_image.visible = false;
                    }
                }
            } else {
                if (main_window.toolbar.sort_order == SortOrder.ASC) {
                    if (accessor.get_index1() >= 0) {
                        right_image.visible = true;
                        right_image.open(accessor.get_file1().get_path());
                    } else {
                        right_image.visible = false;
                    }
                    if (accessor.get_index2() >= 0) {
                        left_image.visible = true;
                        left_image.open(accessor.get_file2().get_path());
                    } else {
                        left_image.visible = false;
                    }
                } else {
                    if (accessor.get_index1() >= 0) {
                        left_image.visible = true;
                        left_image.open(accessor.get_file1().get_path());
                    } else {
                        left_image.visible = false;
                    }
                    if (accessor.get_index2() >= 0) {
                        right_image.visible = true;
                        right_image.open(accessor.get_file2().get_path());
                    } else {
                        right_image.visible = false;
                    }
                }
            }
            main_window.image_next_button.sensitive = is_next_button_sensitive();
            main_window.image_prev_button.sensitive = is_prev_button_sensitive();
        }

        public void open(File file1) throws Error {
            accessor.set_file1(file1);
            open_by_accessor_current_index();
        }

        public void reopen() throws Error {
            open_by_accessor_current_index();
        }

        public void update_title() {
            if (left_image.has_image || right_image.has_image) {
                string title = TITLE_FORMAT.printf(
                        left_image.fileref.get_basename(), left_image.original_width,
                        left_image.original_height, left_image.size_percent,
                        right_image.fileref.get_basename(), right_image.original_width,
                        right_image.original_height, right_image.size_percent);
                title_changed(title);
            }
        }

        public void close() {
            return;
        }
    }
}
