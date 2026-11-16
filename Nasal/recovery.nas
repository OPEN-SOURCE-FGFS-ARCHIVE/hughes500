###############################################################################
##
##   Sometimes we crashed our Aircrafts :-(
##   Now we can get help from yasim - multiplayer helicopter pilots :-)
##   The great work from Anders Gidenstamm is the root of this script, 
##   written by Marc Kraus :: Lake of Constance Hangar
##
##   Copyright (C) 2012 - 2014  Marc Kraus  (info(at)marc-kraus.de)
##
###############################################################################

# =============================================================================
#               H-21C Piasecki rescue action for your aircraft            
# =============================================================================
var debug = 0;

#Global const
var towel_length        = 50.0;
var my_altCor	= 0;

#States
var in_the_air          = 0;
var in_mount_range      = 0;

var delta_roll	= 0;
var delta_pitch = 0;

#################################################################################
############################## crash control ###################################

#If menu ticked open dialog
setlistener("/sar_service/helicopter_rescue", func(oje) {
     if(debug) print("Emergency call was canceled ...");
     if(oje.getBoolValue()){
        sar_service.sar_dialog.show();
        in_the_air = 0;
     }
}, 1, 0);

#If selected SAR heli
setlistener("/sar_service/sar-callsign", func(sar_callsign) {
     if(debug) print("SAR Pilot was selected.");
     if(sar_callsign.getValue()){
        setprop("/sim/multiplay/chat", "");
        setprop("/sim/multiplay/chat", ":: MAYDAY :: MAYDAY :: MAYDAY :: BIRD DOWN!!");
        settimer( func { setprop("/sim/multiplay/chat", "I'm here, "~sar_callsign.getValue()~", please help me!"); }, 3);
	my_altCor = getprop("/position/altitude-agl-ft");
        setprop("/sar_service/sar-locked", 1);
        in_the_air = 0;
        in_mount_range = 0;
        var mp   = props.globals.getNode("/ai/models").getChildren("multiplayer");
	
	#Find the SAR ship index number and check that it had't crashed
	forindex(var v; mp) {
	    if(mp[v].getNode("callsign").getValue() == sar_callsign.getValue() and
	       mp[v].getNode("id").getValue() >= 0){	#Check if not crashed
	    
	       var sar_index = v;
	    }
        }

        if(debug) print(sar_index);
        rescue_me(sar_index);
     }else{
        if(in_the_air == 1) {
            setprop("/sar_service/sar-callsign", "");
            setprop("/sar_service/sar-locked", 0);
            setprop("/sim/crashed",0);
        }
        setprop("/sar_service/helicopter_rescue",0);
        setprop("/sar_service/sar-locked",0);
        setprop("/controls/shadow-and-fire", 1);
        in_mount_range = 0;
     }
}, 1, 0);

############################### Rescue procedure ###############################

var rescue_me = func(v) {
  
    if (v != nil and v >= 0){
      var sar_mp = props.globals.getNode("/ai/models/multiplayer[" ~v~ "]");
      yourLocked  = getprop("/sar_service/sar-locked") or 0;

      #If heli selected and message sent
      if(yourLocked){
         var my_alt   = props.globals.getNode("/position/altitude-ft");
	 var my_alt_m = my_alt.getValue()*FT2M;
	 var my_pos_lat = getprop("/position/latitude-deg");
         var my_pos_lon = getprop("/position/longitude-deg");

         var heaving_heli_alt = getprop("/ai/models/multiplayer["~v~"]/position/altitude-ft") - towel_length;
	 var my_alt_agl = (my_alt_m - geo.elevation( my_pos_lat, my_pos_lon, my_alt_m)) * M2FT;
	 var ground = my_alt_agl - my_altCor ;

         # if we are on ground and not on heaving procedure, look for the distance to the hook
         if (in_the_air == 0){

           var sar_pos_lat = getprop("/ai/models/multiplayer["~v~"]/position/latitude-deg"); 
           var sar_pos_lon = getprop("/ai/models/multiplayer["~v~"]/position/longitude-deg");
           
           if((math.abs(sar_pos_lat - my_pos_lat) <= 0.00008) and (math.abs(sar_pos_lon - my_pos_lon) <= 0.0012)){
              in_mount_range = 1;
           }else{
              in_mount_range = 0;
           }
         }

         #In range and not touching gnd
         if(ground >= -0.0001 and in_mount_range){
              in_the_air = 1;
              setprop("/controls/shadow-and-fire", 0);
              setprop("/sim/crashed", 1);
              my_alt.setValue(heaving_heli_alt);
	      setprop("/position/altitude-agl-ft",my_alt_agl);

              setprop("/position/longitude-deg", getprop("/ai/models/multiplayer["~v~"]/position/longitude-deg"));
              setprop("/position/latitude-deg", getprop("/ai/models/multiplayer["~v~"]/position/latitude-deg"));

	      var pitch= getprop("/orientation/pitch-deg") - delta_pitch;
	      var roll = getprop("/orientation/roll-deg") - delta_roll;
	      delta_pitch = getprop("/ai/models/multiplayer["~v~"]/orientation/pitch-deg");
	      delta_roll = getprop("/ai/models/multiplayer["~v~"]/orientation/roll-deg");
              setprop("/orientation/pitch-deg", pitch + delta_pitch);
              setprop("/orientation/roll-deg", roll + delta_roll); 

	      setprop("/sim/multiplay/generic/float[20]", getprop("/yasim/gross-weight-lbs")); 
      
              if(debug){
                  print("Lifting operation runing.");
                  print("Ground: "~ground);
                  print("my_alt: "~my_alt.getValue());
                  print("heaving__alt "~heaving_heli_alt);
                  print("mounted "~in_mount_range);
              }
          }else{       # Not hooked
              if(in_the_air == 1) {
                  setprop("/sar_service/sar-callsign", "");
                  setprop("/sar_service/sar-locked", 0);
                  setprop("/sim/crashed",0);
              }

              in_mount_range = 0;
              in_the_air = 0;
          }

          settimer( func { rescue_me(v); }, 0);
	
       # No heli selected
       }else{
          # if nobody is in range... nobody can help. So set /sar_service back to 0
          # setprop("/sim/crashed",0);
          setprop("/sar_service/helicopter_rescue",0);
          setprop("/sar_service/sar-callsign","");
          setprop("/controls/shadow-and-fire", 1);
          in_mount_range = 0;
          if(in_the_air == 1) {
              setprop("/sim/crashed",0);
          }
          in_the_air = 0;
          if(debug) print("Hook released."); 
       } 
     } # end v nil control

}

#Set new menu entry
var list= props.globals.getNode("/sim/menubar/default").getChildren("menu");
var menup = "/sim/menubar/default/menu[" ~ size(list) ~ "]/";
setprop (menup ~ "enabled", 'true');
setprop (menup ~ "label", "SAR");

#Set new SAR item    
var m_item = menup ~ "item/";
setprop (m_item ~ "label", "Call SAR helicopter");
setprop (m_item ~ "binding/command", "property-assign");
setprop (m_item ~ "binding/property", "/sar_service/helicopter_rescue");
setprop (m_item ~ "binding/value", 1);

fgcommand("gui-redraw");



################## new menu for the SAR Pilot selection ########################
var SAR_DLG = 0;
var sar_dialog = {};
############################################################
sar_dialog.init = func (x = nil, y = nil) {
    me.x = x;
    me.y = y;
    me.bg = [0, 0, 0, 0.3];    # background color
    me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
    #
    # "private"
    me.title = "SAR";
    me.basenode = props.globals.getNode("/sar_service", 1);
    me.dialog = nil;
    me.namenode = props.Node.new({"dialog-name" : me.title });
    me.listeners = [];
}
############################################################
sar_dialog.create = func {
    if (me.dialog != nil)
        me.close();

    me.dialog = gui.Widget.new();
    me.dialog.set("name", me.title);
    if (me.x != nil)
        me.dialog.set("x", me.x);
    if (me.y != nil)
        me.dialog.set("y", me.y);

    me.dialog.set("layout", "vbox");
    me.dialog.set("default-padding", 0);
    var titlebar = me.dialog.addChild("group");
    titlebar.set("layout", "hbox");
    titlebar.addChild("empty").set("stretch", 1);
    titlebar.addChild("text").set("label", "SAR pilots in range");
    var w = titlebar.addChild("button");
    w.set("pref-width", 16);
    w.set("pref-height", 16);
    w.set("legend", "");
    w.set("default", 0);
    w.set("key", "esc");
    w.setBinding("nasal", "sar_service.sar_dialog.destroy(); ");
    w.setBinding("dialog-close");
    me.dialog.addChild("hrule");

    var content = me.dialog.addChild("group");
    content.set("layout", "vbox");
    content.set("halign", "center");
    content.set("default-padding", 5);

    # Generate the dialog contents.
    me.players = me.find_sar_players();
    var i = 0;
    var tmpbase  = me.basenode.getNode("dialog", 1);
    var selected = me.basenode.getNode("sar-callsign").getValue();
    foreach (var p; me.players) {
        var tmp = tmpbase.getNode("b[" ~ i ~ "]", 1);
        tmp.setBoolValue(streq(selected, p));
        var w = content.addChild("checkbox");
        w.node.setValues({"label"    : p,
                          "halign"   : "left",
                          "property" : tmp.getPath()});
        w.setBinding
            ("nasal",
             "sar_service.sar_dialog.select_action(" ~ i ~ ");");
        i = i + 1;
    }
    me.dialog.addChild("hrule");

    # Display the dialog.
    fgcommand("dialog-new", me.dialog.prop());
    fgcommand("dialog-show", me.namenode);
}
############################################################
sar_dialog.close = func {
    fgcommand("dialog-close", me.namenode);
}
############################################################
sar_dialog.destroy = func {
    SAR_DLG = 0;
    me.close();
    me.basenode.getNode("helicopter_rescue").setValue(0);
    foreach(var l; me.listeners)
        removelistener(l);
    delete(gui.dialog, "\"" ~ me.title ~ "\"");
}
############################################################
sar_dialog.show = func {
#    print("Showing MPCopilots dialog!");
    if (!SAR_DLG) {
        SAR_DLG = int(getprop("/sim/time/elapsed-sec"));
        me.init();
        me.create();
        me._update_(SAR_DLG);
    }
}
############################################################
sar_dialog._redraw_ = func {
    if (me.dialog != nil) {
        me.close();
        me.create();
    }
}
############################################################
sar_dialog._update_ = func (id) {
    if (SAR_DLG != id) return;
    me._redraw_();
    settimer(func { me._update_(id); }, 5.0);
}
############################################################
sar_dialog.select_action = func (n) {
    var selected = me.basenode.getNode("sar-callsign").getValue();
    var bs = me.basenode.getNode("dialog").getChildren();
    # Assumption: There are two true b:s or none. The one not matching selected
    #             is the new selection.
    var i = 0;
    me.basenode.getNode("sar-callsign").setValue("");
    foreach (var b; bs) {
        if (!b.getValue() and (i == n)) {
            b.setValue(1);
            me.basenode.getNode("sar-callsign").setValue(me.players[i]);
        } else {
            b.setValue(0);
        }
        i = i + 1;
    }
    #dual_control.main.reset();
    me._redraw_();
}
############################################################
# Return a list containing all nearby copilot players of the right type.
sar_dialog.find_sar_players = func {
    var mpplayers =
        props.globals.getNode("/ai/models").getChildren("multiplayer");

    var res = [];
    foreach (var pilot; mpplayers) {
        if ((pilot.getNode("valid") != nil) and
            (pilot.getNode("valid").getValue()) and
            (pilot.getNode("sim/model/path") != nil)) {
            var type = pilot.getNode("sim/model/path").getValue();
	    
	 #Old validation code. Change later to "self published SAR" aircraft filter
	 #  foreach (var type_id; me.sar_type){
         #  	if (streq(type,type_id)) {
         #         append(res, pilot.getNode("callsign").getValue());
	 #      }
         #  }

	     append(res, pilot.getNode("callsign").getValue());
        }
    }
#    debug.dump(res);
    return res; 
}
###############################################################################
