extends Sprite3D
class_name poi

@export var header: String;
@export var body: String;


## This POI has been pressed. Adapt accordingly
func pressed():
	if !PopupManager.has_popup(self):
		PopupManager.create_popup(self, header, body);
	else:
		PopupManager.close_popup(self)
