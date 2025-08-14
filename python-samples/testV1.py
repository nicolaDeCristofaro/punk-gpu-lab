# serve_inference.py
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig, pipeline
import gradio as gr

model_id = "HuggingFaceH4/zephyr-7b-beta"            # MIT‑licensed, no gating
bnb_cfg  = BitsAndBytesConfig(load_in_4bit=True)      # 4-bit NF4 weights

model     = AutoModelForCausalLM.from_pretrained(model_id,
                                                 quantization_config=bnb_cfg,
                                                 device_map="auto")      # puts it on the T4
tokenizer = AutoTokenizer.from_pretrained(model_id)

generator = pipeline("text-generation", model=model, tokenizer=tokenizer,
                     max_new_tokens=256, top_p=0.9, temperature=0.7)

def chat(prompt):
    return generator(prompt)[0]["generated_text"]

demo = gr.Interface(fn=chat, inputs="text", outputs="text",
                    title="GPU‑powered Zephyr‑7B Chatbot")
demo.launch(server_name="0.0.0.0", server_port=7860)