#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <ws2812/ws2812.h>
#include <driver/gpio.h>

namespace m2d
{
	#define kVoltage 3.3

	class EmoT
	{
		private:
			int _sensorValues[5] = { 0 };
			int _numberOfLEDs = 0;
			gpio_num_t _pin = GPIO_NUM_13;
			unsigned char *_currentImageAddr = nullptr;
			rgbVal *pixels;
			int _brightness = 255;
			void setup();

		public:
			typedef enum {
				blink
			} AnimationType;
			
			EmoT(int numberOfLEDs, gpio_num_t pin);
			void setBrightness(int brightness);
			void updateValues();
			int getSensorValue(int index);
			int getCurrentSensorValue(int index);
			void draw(unsigned char img[16][16][3], bool flip = false);
			void animate(AnimationType anim);
			void clear();
	};
}

#ifdef __cplusplus
}
#endif
