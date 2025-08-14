# serve_inference.py
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig, pipeline
import torch, threading
from transformers import TextIteratorStreamer
import gradio as gr

model_id = "HuggingFaceH4/zephyr-7b-beta"            # MIT‑licensed, no gating
bnb_cfg  = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_use_double_quant=True,
    bnb_4bit_compute_dtype=torch.float16
)

model     = AutoModelForCausalLM.from_pretrained(model_id,
                                                 quantization_config=bnb_cfg,
                                                 device_map="auto")      # puts it on the T4
tokenizer = AutoTokenizer.from_pretrained(model_id)

def stream_chat(prompt: str):
    # Tokenise once and keep explicit tensors for clarity
    enc = tokenizer(prompt, return_tensors="pt").to(model.device)

    streamer = TextIteratorStreamer(
        tokenizer,
        skip_prompt=True,
        skip_special_tokens=True,
    )

    gen_kwargs = dict(
        input_ids=enc["input_ids"],
        attention_mask=enc["attention_mask"],
        streamer=streamer,
        max_new_tokens=512,
        do_sample=True,
        temperature=0.7,
        top_p=0.9,
    )

    # Run generation in a worker thread so we can yield tokens as they arrive
    threading.Thread(target=model.generate, kwargs=gen_kwargs).start()

    partial = ""
    for token in streamer:
        partial += token
        yield partial

output_box = gr.Textbox(lines=4, max_lines=None, label="Answer", interactive=False)

demo = gr.Interface(
    fn=stream_chat,
    inputs=gr.Textbox(lines=4, label="Prompt"),
    outputs=output_box,
    title="GPU‑powered Zephyr‑7B Chatbot",
    allow_flagging="never"
)
demo.launch(server_name="0.0.0.0", server_port=7860)
# demo.launch(share=True)