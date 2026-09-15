extends Sprite3D
class_name poi

@export var header: String;
@export var body: String;


## This POI has been pressed. Adapt accordingly
func pressed():
	if !PopupManager.has_popup(self):
		PopupManager.create_popup(self, "Lorem", "Lorem ipsum dolor sit amet, consectetur adipiscing elit. In non porttitor augue, in blandit dolor. 
										 Etiam gravida lobortis odio, in bibendum justo rhoncus eget. Donec semper nec erat ut eleifend. 
										 Morbi a est nisl. Quisque dignissim blandit dapibus. Vivamus sodales sagittis mauris vel placerat. 
										 Suspendisse gravida vel mi eget accumsan. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. 
										 Fusce facilisis auctor consectetur. Proin id velit a lacus sollicitudin facilisis et ac erat. 
										 Nulla elementum risus nec justo facilisis, dapibus porta mauris tempor. In sed velit eros.");
	else:
		PopupManager.close_popup(self)
