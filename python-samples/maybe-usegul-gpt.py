

"""
Gradio demo for running OpenAI gpt-oss models via Transformers, with a safe
fallback for non-Hopper GPUs. Based on the OpenAI Cookbook guidance.

Usage:
  python /mnt/persistent-data/gpt-oss-test.py
Then open http://localhost:7860 (via SSM port forwarding or VS Code AWS Toolkit).

Env vars:
  MODEL_ID            (default: openai/gpt-oss-20b)
  FALLBACK_MODEL_ID   (default: EleutherAI/gpt-neox-20b)
  SYSTEM_PROMPT       (default: "")
"""

import os
import threading
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, TextIteratorStreamer
import gradio as gr

MODEL_ID = os.getenv("MODEL_ID", "openai/gpt-oss-20b")
FALLBACK_MODEL_ID = os.getenv("FALLBACK_MODEL_ID", "EleutherAI/gpt-neox-20b")
SYSTEM_DEFAULT = os.getenv("SYSTEM_PROMPT", "")


def _load_native(model_id: str):
    """Load a model/tokenizer in the cookbook style (MXFP4/bfloat16) with device_map=auto.
    This works for gpt-oss on GPUs that support its default quantization (Hopper+).
    """
    tok = AutoTokenizer.from_pretrained(model_id)
    mdl = AutoModelForCausalLM.from_pretrained(
        model_id,
        device_map="auto",
        torch_dtype="auto",
    )
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token
    return tok, mdl, "native"


def _load_bnb_4bit(model_id: str):
    """Fallback: load an alternative model in 4-bit NF4 via bitsandbytes for older GPUs (e.g., T4/A10G)."""
    from transformers import BitsAndBytesConfig

    bnb = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_use_double_quant=True,
        bnb_4bit_compute_dtype=torch.float16,
    )

    tok = AutoTokenizer.from_pretrained(model_id)
    mdl = AutoModelForCausalLM.from_pretrained(
        model_id,
        quantization_config=bnb,
        device_map="auto",
        torch_dtype=torch.float16,
    )
    if tok.pad_token is None:
        tok.pad_token = tok.eos_token
    return tok, mdl, "bnb-4bit"


def load_model():
    """Try native gpt-oss first; if that fails (e.g., kernels not supported), fall back to bnb 4-bit model."""
    try:
        return _load_native(MODEL_ID)
    except Exception as e1:
        # Fall back to a widely available 20B model that fits with 4-bit on 24GB GPUs
        try:
            return _load_bnb_4bit(FALLBACK_MODEL_ID)
        except Exception as e2:
            raise RuntimeError(
                f"Failed to load primary ({MODEL_ID}) and fallback ({FALLBACK_MODEL_ID}) models:\n  primary: {e1}\n  fallback: {e2}"
            )


# Load once at startup
print(f"[gpt-oss] Loading model: {MODEL_ID} (fallback: {FALLBACK_MODEL_ID})")
tokenizer, model, backend = load_model()
print(f"[gpt-oss] Ready. Backend: {backend}; device(s): {model.device if hasattr(model, 'device') else 'auto map'}")


def stream_chat(user_prompt: str, system_prompt: str, max_new_tokens: int, temperature: float, top_p: float):
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": user_prompt})

    inputs = tokenizer.apply_chat_template(
        messages,
        add_generation_prompt=True,
        return_tensors="pt",
        return_dict=True,
    ).to(model.device)

    streamer = TextIteratorStreamer(
        tokenizer,
        skip_prompt=True,
        skip_special_tokens=True,
    )

    gen_kwargs = dict(
        **inputs,
        streamer=streamer,
        max_new_tokens=int(max_new_tokens),
        do_sample=True,
        temperature=float(temperature),
        top_p=float(top_p),
        eos_token_id=tokenizer.eos_token_id,
        pad_token_id=tokenizer.eos_token_id,
    )

    thread = threading.Thread(target=model.generate, kwargs=gen_kwargs)
    thread.start()

    partial = ""
    for token in streamer:
        partial += token
        yield partial


with gr.Blocks(title=f"{MODEL_ID} ({backend})") as demo:
    gr.Markdown(f"### {MODEL_ID} — Live Chat  \nBackend: **{backend}**.  \n*Tip: use VS Code AWS Toolkit or SSM port forwarding to open http://localhost:7860 locally.*")

    with gr.Row():
        system_in = gr.Textbox(label="System prompt (optional)", value=SYSTEM_DEFAULT)
    prompt_in = gr.Textbox(label="User prompt", lines=4)

    with gr.Row():
        max_tokens = gr.Slider(16, 4096, value=256, step=8, label="max_new_tokens")
    with gr.Row():
        temperature = gr.Slider(0.0, 1.5, value=0.7, step=0.05, label="temperature")
        top_p = gr.Slider(0.1, 1.0, value=0.9, step=0.05, label="top_p")

    out = gr.Textbox(label="Assistant", lines=12)
    go = gr.Button("Generate")

    go.click(stream_chat, inputs=[prompt_in, system_in, max_tokens, temperature, top_p], outputs=out)
    prompt_in.submit(stream_chat, inputs=[prompt_in, system_in, max_tokens, temperature, top_p], outputs=out)


demo.launch(server_name="0.0.0.0", server_port=7860)