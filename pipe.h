// Ring buffer that takes heavy advantage of constant folding
#pragma once

#include "Common.h"

typedef struct Pipe_data{
	uint8_t* volatile read_ptr;
	uint8_t* volatile write_ptr;
	volatile uint8_t count;
} Pipe_data;

typedef struct Pipe{
	Pipe_data* data;
	uint8_t* buffer;
	uint16_t size;
	uint8_t count;
} Pipe;

#define PIPE_H(NAME, SIZE, COUNT)       \
	extern Pipe_data NAME##_data;       \
	extern uint8_t NAME##_buffer[(COUNT)][(SIZE)];   \
	const static Pipe NAME = {          \
		.data = &(NAME##_data),            \
		.buffer = (NAME##_buffer)[0],       \
		.size = (SIZE),                 \
		.count = (COUNT)                \
	};


#define PIPE_C(NAME, SIZE, COUNT)            \
	uint8_t NAME##_buffer[(COUNT)][(SIZE)];  \
	Pipe_data NAME##_data = {                \
		.read_ptr = (NAME##_buffer)[0],          \
		.write_ptr = (NAME##_buffer)[0],         \
		.count = 0                           \
	};

#define PIPE(NAME, SIZE, COUNT) \
	PIPE_H(NAME, SIZE, COUNT)   \
	PIPE_C(NAME, SIZE, COUNT)

inline uint8_t pipe_can_read(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline uint8_t pipe_can_read(const Pipe* pipe){
	return pipe->data->count;
}

inline uint8_t pipe_can_write(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline uint8_t pipe_can_write(const Pipe* pipe){
	return pipe->count - pipe->data->count;
}

inline void pipe_done_read(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline void pipe_done_read(const Pipe* pipe){
	pipe->data->count--;
	uint8_t* p = pipe->data->read_ptr + pipe->size;
	if (p >= pipe->buffer + ((uint16_t)pipe->size)*pipe->count) p = pipe->buffer;
	pipe->data->read_ptr = p;
}

inline void pipe_done_write(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline void pipe_done_write(const Pipe* pipe){
	uint8_t* p = pipe->data->write_ptr + pipe->size;
	if (p >= pipe->buffer + ((uint16_t)pipe->size)*pipe->count) p = pipe->buffer;
	pipe->data->write_ptr = p;
	pipe->data->count++;
}

inline uint8_t* pipe_read_ptr(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline uint8_t* pipe_read_ptr(const Pipe* pipe){
	return pipe->data->read_ptr;
}

inline uint8_t* pipe_write_ptr(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline uint8_t* pipe_write_ptr(const Pipe* pipe){
	return pipe->data->write_ptr;
}

inline void pipe_reset(const Pipe* pipe) ATTR_ALWAYS_INLINE;
inline void pipe_reset(const Pipe* pipe){
	pipe->data->count = 0;
	pipe->data->read_ptr = pipe->data->write_ptr = pipe->buffer;
}


