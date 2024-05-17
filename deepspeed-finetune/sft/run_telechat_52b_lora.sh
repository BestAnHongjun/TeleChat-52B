#!/bin/bash
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: Apache-2.0

# DeepSpeed Team
OUTPUT=test
ZERO_STAGE=3
HOST=my_hostfile
MAX_LEN=1024
NUM_SAMPLES=10000
DATA_OUTPUT_PATH=datas/data_files
MODEL_PATH=$1


if [ "$OUTPUT" == "" ]; then
    OUTPUT=./output
fi
if [ "$ZERO_STAGE" == "" ]; then
    ZERO_STAGE=3
fi
mkdir -p $OUTPUT

python -u process_data.py \
   --data_path data.json  \
   --tokenizer_path $MODEL_PATH \
   --data_output_path $DATA_OUTPUT_PATH \
   --max_seq_len $MAX_LEN \
   --num_samples $NUM_SAMPLES \
   --num_workers 10 \
   --process_method multiple \
   --seed 42

deepspeed --master_port 29500 --hostfile=$HOST main.py \
   --data_path $DATA_OUTPUT_PATH  \
   --model_name_or_path $MODEL_PATH \
   --per_device_train_batch_size 1 \
   --max_seq_len $MAX_LEN \
   --with_loss_mask \
   --learning_rate 3e-5 \
   --weight_decay 0.0001 \
   --num_train_epochs 1 \
   --gradient_accumulation_steps 4 \
   --lr_scheduler_type cosine \
   --warmup_proportion 0.1 \
   --gradient_checkpointing \
   --seed 42 \
   --zero_stage $ZERO_STAGE \
   --lora_dim 8 \
   --mark_only_lora_as_trainable \
   --lora_module_name "attn.c_attn" \
   --save_steps 100 \
   --deepspeed \
   --output_dir $OUTPUT \
   2>&1 | tee $OUTPUT/training.log
