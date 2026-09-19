class_name GlobeWaypoint
extends Node3D

signal clicked(waypoint: GlobeWaypoint)

@export var focus_zoom_distance: float = 2.2


func _ready() -> void:
	add_to_group("globe_waypoints")


func on_clicked() -> void:
	clicked.emit(self)
