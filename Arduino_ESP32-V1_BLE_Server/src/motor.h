#ifndef MOTOR_H
#define MOTOR_H

#include <ESP32Servo.h>
#include "driver/mcpwm.h"

// Motor Pin Definitions
#define GPIO_PWM0A_OUT 1
#define GPIO_PWM0B_OUT 2

// Function Prototypes
void motor_init();
void motor_forward(float duty_cycle);
void motor_backward(float duty_cycle);
void motor_stop();

#endif
