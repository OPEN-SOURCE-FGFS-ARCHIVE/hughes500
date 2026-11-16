# Initialize properties
setprop("/systems/electrical/battery/voltage", 0);
setprop("/systems/electrical/battery/current", 0);
setprop("/controls/electric/battery-switch", 0);
setprop("/controls/electric/avionics-switch", 0);
setprop("/controls/electric/engine/generator", 0);
setprop("/systems/electrical/generator/voltage", 0);
setprop("/systems/electrical/generator/current", 0);
setprop("/systems/electrical/avionics/power", 0);
setprop("/systems/electrical/lights/beacon", 0);
setprop("/systems/electrical/lights/landing", 0);
setprop("/systems/electrical/lights/nav", 0);
setprop("/systems/electrical/lights/strobe", 0);
setprop("/systems/electrical/lights/search", 0);
setprop("/controls/lighting/instrument-lights", 0);
setprop("/systems/electrical/outputs/com1", 0);
setprop("/systems/electrical/outputs/nav1", 0);

var batteryCapacity = 17;
var temperature = getprop("/environment/temperature-degc");
var generatorOn = getprop("/controls/electric/engine/generator");

var batteryCharge = func(temperature) {
    if (temperature >= -39 and temperature <= 69) {
        if (temperature < 3 or temperature > 55) {
            batteryCapacity = batteryCapacity / 2;
        }
    } else {
        return 0;
    }
    return batteryCapacity;
};

var voltageOutput = func(batteryCapacity) {
    if (batteryCapacity > 0) {
        return 26.4;
    } else {
        return 0;
    }
};

var currentOutput = func(voltageOutput) {
    if (voltageOutput > 0) {
        return 500;
    } else {
        return 0;
    }
};

setlistener("/controls/electric/battery-switch", func {
    if (getprop("/controls/electric/battery-switch") == 1) {
        var temperature = getprop("/environment/temperature-degc");
        var capacity = batteryCharge(temperature);
        var outputVoltage = voltageOutput(capacity);
        var outputCurrent = currentOutput(outputVoltage);

        if (outputVoltage > 0 and outputCurrent > 0) {
            setprop("/systems/electrical/battery/voltage", outputVoltage);
            setprop("/systems/electrical/battery/current", outputCurrent);
            setprop("/controls/electric/avionics-switch", 1);
        } else {
            setprop("/controls/electric/avionics-switch", 0);
        }
    } else {
        setprop("/systems/electrical/battery/voltage", 0);
        setprop("/systems/electrical/battery/current", 0);
        setprop("/controls/electric/avionics-switch", 0);
    }
});

setlistener("/controls/electric/engine/generator", func {
    if (getprop("/controls/electric/engine/generator") == 1) {
        setprop("/systems/electrical/generator/voltage", 28);
        setprop("/systems/electrical/generator/current", 500);

        # Check if the battery is not fully charged
        if (batteryCapacity < 17) {
            batteryCapacity = math.min(batteryCapacity + 0.1, 17); # Increment the battery capacity while charging
        }
    } else {
        setprop("/systems/electrical/generator/voltage", 0);
        setprop("/systems/electrical/generator/current", 0);
    }
});

setlistener("/controls/electric/avionics-switch", func {
    var avionicsPower = getprop("/controls/electric/avionics-switch");

    if (avionicsPower == 1) {
        setprop("/systems/electrical/avionics/power", 1);
        setprop("/systems/electrical/lights/beacon", 1);
        setprop("/systems/electrical/lights/landing", 1);
        setprop("/systems/electrical/lights/nav", 1);
        setprop("/systems/electrical/lights/strobe", 1);
        setprop("/systems/electrical/lights/search", 1);
        setprop("/controls/lighting/instrument-lights", 1);
        setprop("/systems/electrical/outputs/com1", 1);
        setprop("/systems/electrical/outputs/nav1", 1);

    } else {
        setprop("/systems/electrical/avionics/power", 0);
        setprop("/systems/electrical/lights/beacon", 0);
        setprop("/systems/electrical/lights/landing", 0);
        setprop("/systems/electrical/lights/nav", 0);
        setprop("/systems/electrical/lights/strobe", 0);
        setprop("/systems/electrical/lights/search", 0);
        setprop("/controls/lighting/instrument-lights", 0);
        setprop("/systems/electrical/outputs/com1", 0);
        setprop("/systems/electrical/outputs/nav1", 0);
    }
});
