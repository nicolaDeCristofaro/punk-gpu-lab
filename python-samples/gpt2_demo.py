import gradio as gr
from transformers import pipeline

# ─── Load a tiny model on GPU 0 ─────────────────────────────────────────────
generator = pipeline(
    task="text-generation",
    model="gpt2",
    device=0,           # <-- forces CUDA
    torch_dtype="auto"
)

# ─── Inference function ────────────────────────────────────────────────────
def generate(prompt):
    out = generator(prompt, max_new_tokens=60, do_sample=True, top_p=0.9)[0]
    return out["generated_text"]

# ─── Gradio UI ─────────────────────────────────────────────────────────────
demo = gr.Interface(
    fn=generate,
    inputs=gr.Textbox(lines=2, placeholder="Write a prompt…"),
    outputs="text",
    title="GPT-2 Demo (GPU)"
)

demo.launch(server_name="0.0.0.0", server_port=7860, share=False)