import gradio as gr, torch
from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline

MODEL_ID = "Qwen/Qwen1.5-7B-Chat"      # fully open, MIT licence

print("🔄 Loading Qwen-1.5-7B-Chat … ⏳")

tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, use_fast=True)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID,
    device_map="auto",                 # GPU-offload handled for you
    torch_dtype=torch.float16,         # fits 24 GB cards comfortably
)

generator = pipeline(
    "text-generation",
    model=model,
    tokenizer=tokenizer,
    device_map="auto",
    max_new_tokens=256,
    do_sample=True,
    top_p=0.9,
)

def chat(user_msg, history):
    history.append([user_msg, ""])                  # placeholder
    prompt = "\n".join([f"User: {u}\nAssistant: {a}" for u, a in history[:-1]])
    prompt += f"\nUser: {user_msg}\nAssistant:"
    reply = generator(prompt)[0]["generated_text"].split("Assistant:", 1)[-1].strip()
    history[-1][1] = reply
    return history, history

with gr.Blocks(title="Qwen-1.5-7B-Chat (GPU, no token)") as demo:
    gr.Markdown("### Chat with Qwen-1.5-7B-Chat — runs locally on your EC2 GPU")
    chatbot = gr.Chatbot()
    txt = gr.Textbox(placeholder="Ask me anything…")
    state = gr.State([])

    txt.submit(lambda x, s: ("", s + [[x, ""]]), [txt, state], [txt, state]) \
       .then(chat, [txt, state], [chatbot, state])

demo.launch(server_name="0.0.0.0", server_port=7860, share=False)