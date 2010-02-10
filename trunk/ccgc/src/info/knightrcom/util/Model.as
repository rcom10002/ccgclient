package info.knightrcom.util {
    import flash.utils.Dictionary;

    public dynamic class Model {

        /**
         *
         *
         */
        public function Model() {
        }

        public var id:String;

        public var parentId:String;

        public var name:String;

        public var displayIndex:uint;

        public var modelCategory:String;

        public var data:String;

        public var parent:Object;

        public var childContainer:Dictionary = new Dictionary();
    }
}