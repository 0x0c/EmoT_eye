#include <EmoT.h>
#include <Emoticon.h>
#include <vector>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

namespace m2d
{
	#define delay_ms(ms) vTaskDelay((ms) / portTICK_RATE_MS)
	
	EmoT::EmoT(int numberOfLEDs = 256, gpio_num_t pin = GPIO_NUM_13) : _numberOfLEDs(numberOfLEDs), _pin(pin) {
		this->setup();
	}

	void EmoT::setBrightness(int brightness) {
		this->_brightness = brightness;
	}

	void EmoT::draw(unsigned char img[16][16][3], bool flip) {
		if (this->_currentImageAddr != &(img[0][0][0])) {
			this->_currentImageAddr = &(img[0][0][0]);
			if (flip) {
				// for (int time = 0; time <= 8; time++) {
					for (int i = 16 * 16; i >= 0; i--) {
						int idx = i / 16;
						int row = i % 16;
						int pos = i;

						float ratio = 1;//time / 8.0;
						rgbVal c = makeRGBVal(img[row][idx][0] * ratio, img[row][idx][1] * ratio, img[row][idx][2] * ratio, this->_brightness);
						if (row % 2) {
							pos = (row + 1) * 16 - idx - 1;
						}
						this->pixels[pos] = c;
					}
					ws2812_setColors(this->_numberOfLEDs, pixels);
					// delay_ms(35);
				// }
			}
		 	else {
		 		// for (int time = 0; time <= 8; time++) {
					for (int i = 0; i < 16 * 16; i++) {
						int row = i / 16;
						int idx = i % 16;
						int pos = i;

						float ratio = 1;//time / 8.0;
						rgbVal c = makeRGBVal(img[row][idx][0] * ratio, img[row][idx][1] * ratio, img[row][idx][2] * ratio, this->_brightness);
						if (row % 2) {
							pos = (row + 1) * 16 - idx - 1;
						}
						this->pixels[pos] = c;
					}
					ws2812_setColors(this->_numberOfLEDs, pixels);
					// delay_ms(35);
				// }
			}
		}
	}

	void EmoT::animate(AnimationType anim) {
		std::vector<unsigned char (*)[16][3]> emoji;
		if (anim == blink) {
			emoji = Emoticon::blink;
		}
		for(auto frame : emoji) {
			for (int i = 0; i < 16 * 16; i++) {
				int row = i / 16;
				int idx = i % 16;
				int pos = i;
				rgbVal c = makeRGBVal(frame[row][idx][0], frame[row][idx][1], frame[row][idx][2], this->_brightness);
				if (row % 2) {
					pos = (row + 1) * 16 - idx - 1;
				}
				this->pixels[pos] = c;
			}
			ws2812_setColors(this->_numberOfLEDs, pixels);
			delay_ms(35);
		}
	}

	void EmoT::clear() {
		this->_currentImageAddr = nullptr;
		for (int i = 0; i < 16 * 16; i++) {
			int row = i / 16;
			int idx = i % 16;
			int pos = i;

			rgbVal c = makeRGBVal(0, 0, 0, 0);
			if (row % 2) {
				pos = (row + 1) * 16 - idx - 1;
			}
			this->pixels[pos] = c;
		}
		ws2812_setColors(this->_numberOfLEDs, pixels);
	}

	void EmoT::setup() {
		ws2812_init(this->_pin);
		this->pixels = (rgbVal *)malloc(sizeof(rgbVal) * this->_numberOfLEDs);
	}
}
