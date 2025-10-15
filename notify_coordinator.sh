#!/bin/bash

# coordinator tmux session에 메시지를 보내는 스크립트

MESSAGE='self-construct라는 이름의 tmux session의 화면을 확인하면 그 안의 claude code가 개발을 진행하고 다음 스텝을 기다리고 있을 거야. 적절하게 선택해주든지 아니면 다음에 뭘 해야 할지를 직접 지시해줘. 지시를 할 때는 tmux sendkey를 이용하면 되는데, 엔터키나 특수키를 보내기 위해서는 하나의 tmux sendkey에 넣는 것이 아니라 새 tmux sendkey command로 엔터키나 특수키를 보내면 돼'

# coordinator session이 존재하는지 확인
if ! tmux has-session -t coordinator 2>/dev/null; then
    echo "Error: coordinator tmux session not found"
    exit 1
fi

# 메시지를 literal로 전송 (-l 옵션)
tmux send-keys -t coordinator -l "$MESSAGE"

# 엔터키는 별도로 전송
tmux send-keys -t coordinator Enter

echo "Message sent to coordinator session"
