#!/usr/bin/env python

from llama_index import StorageContext, load_index_from_storage
from langchain.chat_models import ChatOpenAI
import gradio
import sys
import os
import openai


OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]

openai.api_key = OPENAI_API_KEY;


def chatbot(input_text):

    # rebuild storage context
    storage_context = StorageContext.from_defaults(persist_dir=".")

    # load index
    index = load_index_from_storage(storage_context)

    query_engine = index.as_query_engine()
    response = query_engine.query(input_text)

    return response.response

iface = gradio.Interface(fn=chatbot,
                         inputs=gradio.components.Textbox(lines=7, label="Enter your text"),
                         outputs="text",
                         title="Custom-trained AI Chatbot")

iface.launch(share=True)
