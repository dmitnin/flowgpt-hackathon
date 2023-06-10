#!/usr/bin/env python

from llama_index import StorageContext, load_index_from_storage
from langchain.chat_models import ChatOpenAI
import gradio
import sys
import os
import openai


LLAMA_INDEX_DIR = "./llama_index"

OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]

openai.api_key = OPENAI_API_KEY;

# rebuild storage context
ll_storage_context = StorageContext.from_defaults(persist_dir=LLAMA_INDEX_DIR)

# load index
ll_index = load_index_from_storage(ll_storage_context)
ll_query_engine = ll_index.as_query_engine()


def chatbot(input_text):
    response = ll_query_engine.query(input_text)

    return response.response

iface = gradio.Interface(fn=chatbot,
                         inputs=gradio.components.Textbox(lines=7, label="Enter your text"),
                         outputs="text",
                         title="FlowGPT Hackathon")

iface.launch(share=True)
