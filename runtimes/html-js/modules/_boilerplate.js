// Arrow HTML-JS Runtime: Node-Type (module) boilerplate

class NodeType {

    constructor(node_id, node_resource, node_map, _playing_in_slot) {

        const _self = this;
        // super();

        const AUTO_PLAY_SLOT = -1;
        
        this.get_element = function () {
            return this.html;
        };
        
        this.remove_element = function() {
            this.html.remove();
        };
        
        this.play_forward_from = function(slot_idx){
            slot_idx = safeInt(slot_idx);
            if ( Number.isFinite(slot_idx) == false || slot_idx < 0 ){
                slot_idx = AUTO_PLAY_SLOT;
            }
            if ( this.slots_map.hasOwnProperty(slot_idx) ) {
                var next = this.slots_map[slot_idx];
                play_node(next.id, next.slot);
            } else {
                handle_status(_CONSOLE_STATUS_CODE.END_EDGE, _self);
            }
            this.set_view_played(slot_idx);
        };
        
        this.skip_play = function() {
            this.html.setAttribute('data-skipped', true);
            // Continue the only and natural path even if the node is skipped in auto-play cases
            if (AUTO_PLAY_SLOT >= 0){
                this.play_forward_from(AUTO_PLAY_SLOT);
            }
        };
        
        this.set_view_played = function(slot_idx){
            // ... generally by setting a custom data-attribute, so we can handle it cleaner with css
            this.html.setAttribute('data-played', true);
        };
        
        this.set_view_unplayed = function(){
            // ditto
            this.html.setAttribute('data-played', false);
        };
        
        this.step_back = function(){
            this.set_view_unplayed();
        };
        
        this.proceed = function(){
            // Shall we play a specified slot ?
            // if ( typeof this.playing_in_slot == 'number' && this.playing_in_slot >= 0 ){
                // this.play_forward_from(this.playing_in_slot);
            // or ...
            // } else {
                // handle skip in case,
                if (this.node_map.hasOwnProperty("skip") && this.node_map.skip == true){
                    this.skip_play();
                // otherwise auto-play if set
                } else if ( AUTO_PLAY_SLOT >= 0 ) {
                    this.play_forward_from(AUTO_PLAY_SLOT);
                }
                // Finally if nothing is played, we'll wait for the user interaction
            //}
        };
        
        if ( node_id >= 0 ){
            if ( typeof node_resource == 'object' && typeof node_map == 'object' ){
                // Sort stuff
                this.node_id = node_id;
                this.node_resource = node_resource;
                this.node_map = node_map;
                this.slots_map = remap_connections_for_slots( (node_map || {}), node_id );
                // Create the node html element
                this.html = create_node_base_html(node_id, node_resource);
                    // ... and the children
                    // TODO
                    // this.x_button = create_element("button", node_resource.name);
                    // this.x_button.addEventListener( _CLICK, this.play_forward_from.bind(_self, AUTO_PLAY_SLOT) );
                    // this.html.appendChild(this.x_button);
            }
            // this.playing_in_slot = safeInt(_playing_in_slot);
            return this;
        }
        // We won't get here if construction is done right
        // TODO: replace `NodeType` with the right name
        throw new Error("Unable to construct `NodeType`");
    }
    
}
