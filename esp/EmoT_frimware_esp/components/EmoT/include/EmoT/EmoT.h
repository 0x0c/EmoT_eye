#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <driver/gpio.h>
#include "WS2812/WS2812.h"

namespace m2d
{
	#define kVoltage 3.3

	namespace EmoT
	{
		typedef enum {
			blink
		} AnimationType;

		class Tee
		{
			private:
				int _numberOfLEDs = 256;
				gpio_num_t _pin = GPIO_NUM_13;
				unsigned char *_currentImageAddr = nullptr;
				WS2812 *strip;
				int _brightness = 30;
				void setup();

			public:
				
				Tee(int numberOfLEDs, gpio_num_t pin);
				void setBrightness(int brightness);
				void updateValues();
				int getSensorValue(int index);
				int getCurrentSensorValue(int index);
				void draw(unsigned char img[16][16][3], bool flip = false);
				void animate(AnimationType anim);
				void clear();
				void updatePixel(int index, int r, int g, int b);
				void updatePixel(int index, int r, int g, int b, int brightness);
				void emit();
		};
	}
}

#ifdef __cplusplus
}
#endif
