package info.knightrcom
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import mx.controls.SWFLoader;
	import mx.core.Container;
	
	public class AirLoadSWF
	{
		private var target:Container;
		public function addSwf(target_:Container, fileName:String):void
		{
			target = target_;
			loadLocalSwf(fileName);
		}

		private function loadLocalSwf(fileName:String):void
		{       
		    // File reference
//		    var file:File; 
//		    file = File.applicationStorageDirectory.resolvePath(fileName);
//		
//		    // Open the SWF file
//		    var fileStream:FileStream = new FileStream();
//		    fileStream.open(file, FileMode.READ); 
//		
//		    // Read SWF bytes into byte array and close file
//		    var bytes: ByteArray = new ByteArray();
//		    fileStream.readBytes(bytes);
//		    fileStream.close();
//		
//		    // Prepare the loader context to avoid security error
//		    var loaderContext:LoaderContext = new LoaderContext();
//		    loaderContext.allowLoadBytesCodeExecution = true; 
		
		    // Load the SWF file
		    var swfLoader: SWFLoader = new SWFLoader();
//		    swfLoader.loaderContext = loaderContext;
//		    swfLoader.source = bytes; 
		    swfLoader.load(fileName);
		    // Add to you stage
		    target.addChild(swfLoader);                   
		}
	}
}