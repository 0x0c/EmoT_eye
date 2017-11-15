#include <EmoT.h>
#include <Emoticon.h>
#include <vector>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_log.h>

namespace m2d
{
	namespace EmoT
	{
		#define delay_ms(ms) vTaskDelay((ms) / portTICK_RATE_MS)
		
		Tee::Tee(int numberOfLEDs = 256, gpio_num_t pin = GPIO_NUM_13) : _numberOfLEDs(numberOfLEDs), _pin(pin) {
			this->setup();
		}

		void Tee::setBrightness(int brightness) {
			this->_brightness = brightness;
		}

		void Tee::draw(unsigned char img[16][16][3], bool flip) {
			ESP_LOGI("EmoT", "draw");
			this->clear();
			if (this->_currentImageAddr != &(img[0][0][0])) {
				this->_currentImageAddr = &(img[0][0][0]);
				if (flip) {
					for (int time = 0; time <= 32; time++) {
						for (int i = this->_numberOfLEDs; i >= 0; i--) {
							int idx = i / 16;
							int row = i % 16;
							int pos = i;
							if (row % 2) {
								pos = (row + 1) * 16 - idx - 1;
							}
							float ratio = time / 32.0;
							this->updatePixel(pos, img[row][idx][0], img[row][idx][1], img[row][idx][2], this->_brightness * ratio);
						}
						this->emit();
						delay_ms(35);
					}
				}
				else {
					// for (int time = 0; time <= 32; time++) {
						for (int i = 0; i < this->_numberOfLEDs; i++) {
							int row = i / 16;
							int idx = i % 16;
							int pos = i;
							if (row % 2) {
								pos = (row + 1) * 16 - idx - 1;
							}
							float ratio = 1;//time / 32.0;
							this->updatePixel(pos, img[row][idx][0], img[row][idx][1], img[row][idx][2], this->_brightness * ratio);
						}
						this->emit();
						delay_ms(35);
					// }
				}
			}
		}

		void Tee::animate(AnimationType anim) {
			std::vector<unsigned char (*)[16][3]> emoji;
			if (anim == blink) {
				emoji = Emoticon::blink;
			}
			for(auto frame : emoji) {
				for (int i = 0; i < this->_numberOfLEDs; i++) {
					int row = i / 16;
					int idx = i % 16;
					int pos = i;
					if (row % 2) {
						pos = (row + 1) * 16 - idx - 1;
					}
					this->updatePixel(pos, frame[row][idx][0], frame[row][idx][1], frame[row][idx][2], this->_brightness);
				}
				this->emit();
				delay_ms(35);
			}
		}

		void Tee::clear() {
			ESP_LOGI("EmoT", "clear");
			this->_currentImageAddr = nullptr;
			this->strip->clear();
			// for (int i = 0; i < this->_numberOfLEDs; i++) {
			// 	this->updatePixel(i, 0, 0, 0, 0);
			// }
			this->emit();
		}

		void Tee::setup() {
			this->strip = new WS2812(this->_pin, this->_numberOfLEDs, RMT_CHANNEL_2);
		}

		void Tee::updatePixel(int index, int r, int g, int b) {
			this->updatePixel(index, r, g, b, this->_brightness);
		}

		void Tee::updatePixel(int index, int r, int g, int b, int brightness) {
			if (brightness > 255) {
				brightness = 255;
			}
			if (brightness < 0) {
				brightness = 0;
			}

			this->strip->setPixel(index, r * brightness / 255, g * brightness / 255, b * brightness / 255);
		}
		
		void Tee::emit() {
			ESP_LOGI("EmoT", "emit");
			this->strip->show();
		}
	}
}
