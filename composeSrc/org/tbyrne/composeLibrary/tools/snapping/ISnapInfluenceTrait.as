package org.tbyrne.composeLibrary.tools.snapping
{
	import flash.geom.Vector3D;
	
	import org.tbyrne.compose.traits.ITrait;
	
	public interface ISnapInfluenceTrait extends ITrait
	{
		function get maxAcceptDistance():Number;
		function get groups():Vector.<String>;
		function makeProposal(snappable:ISnappableTrait, snapPoint:ISnapPoint):Vector3D;
		function testProposal(snappable:ISnappableTrait, proposal:Vector3D):Number;
		function beginSnapping(snappable:ISnappableTrait):void;
		function setCurrentProposal(snappable:ISnappableTrait, proposal:Vector3D, snapPoint:ISnapPoint):void;
		function setAcceptedProposal(snappable:ISnappableTrait, proposal:Vector3D, snapPoint:ISnapPoint):void;
	}
}