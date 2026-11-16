#Radio Power Logic
var radiopower = {
   update : func {
        var batswitch = getprop("/controls/electric/directbat-switch");
        var generator = getprop("/controls/electric/engine/generator");
        if (batswitch == 1 or generator == 1) {
            setprop("/controls/electric/radiopower", 1);
        } else {
            setprop("/controls/electric/radiopower", 0);
        }
    },
};

setlistener("/controls/electric/directbat-switch", func {radiopower.update();});
setlistener("/controls/electric/engine/generator", func {radiopower.update();});
