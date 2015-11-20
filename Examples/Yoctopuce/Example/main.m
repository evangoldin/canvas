#include <IOKit/graphics/IOGraphicsLib.h>
#import "yocto_api.h"
#import "yocto_lightsensor.h"
#include <IOKit/IOKitLib.h>

const int kMaxDisplays = 16;
const CFStringRef kDisplayBrightness = CFSTR(kIODisplayBrightnessKey);

void setBrightness(float brightness) {
    CGDirectDisplayID display[kMaxDisplays];
    CGDisplayCount numDisplays;
    CGDisplayErr err;
    err = CGGetActiveDisplayList(kMaxDisplays, display, &numDisplays);
    
    for (CGDisplayCount i = 0; i < numDisplays; ++i) {
        CGDirectDisplayID dspy = display[i];

        CFDictionaryRef originalMode = CGDisplayCurrentMode(dspy);
        if (originalMode == NULL)
            continue;
        
        io_service_t service = CGDisplayIOServicePort(dspy);
                 err = IODisplaySetFloatParameter(service, kNilOptions, kDisplayBrightness,
                                         brightness);
    }
}

float readSensor(void)
{
    YLightSensor *sensor = [YLightSensor FirstLightSensor];
    if (sensor==NULL) {
        NSLog(@"No module connected (check USB cable)");
        return -11;
    }

    if(![sensor isOnline]) {
        NSLog(@"Module not connected (check identification and USB cable)\n");
        return -1;
    }
    
    float sensorValue = [sensor get_currentValue];
    NSLog(@"Current ambient light: %f lx\n", sensorValue);
    
    return sensorValue;
}


int main(int argc, const char * argv[])
{
    NSError *error;
    if([YAPI RegisterHub:@"usb": &error] != YAPI_SUCCESS) {
        NSLog(@"RegisterHub error: %@", [error localizedDescription]);
        return 1;
    }
    
    @autoreleasepool {
        while(true) {
            float sensorValue = readSensor();
            if (sensorValue == -1) {
                return 1;
            }
            [YAPI Sleep:10:NULL];
            setBrightness(sensorValue/100.0f);
        }
        
    }
    return 0;
}