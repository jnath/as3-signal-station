package org.tbyrne.actLibrary.external.siteStream
{
	import org.tbyrne.hoborg.ReadableObjectDescriber;
	
	public class ContentPath
	{
		[Property(toString="true",clonable="true")]
		public var path:String;
		
		[Property(toString="true",clonable="true")]
		public var property:String;
		
		public function ContentPath(path:String, property:String){
			this.path = path;
			this.property = property;
		}
		
		public function toString(): String
		{
			return ReadableObjectDescriber.describe(this);
		}
	}
}