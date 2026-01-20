#pragma once

#include <stdint.h>

typedef struct {
    uint8_t len;
    uint8_t data[255];
} ShortString;

typedef struct {
    ShortString Key;
    ShortString Value;
} TRecord;

typedef struct {
    int32_t Count;
    TRecord Records[255];
} TDB;

typedef struct {
    uint16_t Year;
    uint8_t Month;
    uint8_t Day;
    uint8_t Hour;
    uint8_t Minute;
    uint8_t Second;
    uint8_t Centisecond;
    uint16_t RFU;
    int32_t Blk1;
    int32_t Blk2;
    int32_t Blk3;
    int32_t Blk4;
} TRDSGroup;