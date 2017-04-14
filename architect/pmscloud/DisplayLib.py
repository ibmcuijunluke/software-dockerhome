# -*- coding: utf-8 -*-  
  
from pyvirtualdisplay import Display  
  
display = Display(visible=0, size=(1024, 768))  
##启动虚拟显示  
def start():  
    display.start()  
  
##关闭虚拟显示  
def stop():  
    display.stop()  
