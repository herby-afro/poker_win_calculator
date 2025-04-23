# poker_win_calculator_web.py

import eval7
import random
from typing import List, Optional
import streamlit as st

def calculate_win_probability(
    hole_cards: List[str],
    flop: List[str],
    turn: Optional[str],
    river: Optional[str],
    num_opponents: int = 8,
    iterations: int = 10000
) -> float:

    deck = [card for card in eval7.Deck()]
    used_cards = [eval7.Card(card) for card in hole_cards + flop]
    if turn:
        used_cards.append(eval7.Card(turn))
    if river:
        used_cards.append(eval7.Card(river))

    for card in used_cards:
        deck.remove(card)

    our_hand = [eval7.Card(card) for card in hole_cards]
    board = [eval7.Card(card) for card in flop]
    if turn:
        board.append(eval7.Card(turn))
    if river:
        board.append(eval7.Card(river))

    wins = 0
    ties = 0

    for _ in range(iterations):
        deck_copy = deck[:]
        random.shuffle(deck_copy)

        opponents_hands = []
        for _ in range(num_opponents):
            opponents_hands.append([deck_copy.pop(), deck_copy.pop()])

        sim_board = board[:]
        while len(sim_board) < 5:
            sim_board.append(deck_copy.pop())

        our_score = eval7.evaluate(our_hand + sim_board)
        best_score = our_score
        num_best = 1
        we_win = True

        for opp_hand in opponents_hands:
            opp_score = eval7.evaluate(opp_hand + sim_board)
            if opp_score > best_score:
                best_score = opp_score
                we_win = False
                num_best = 1
            elif opp_score == best_score:
                num_best += 1

        if we_win and num_best == 1:
            wins += 1
        elif best_score == our_score:
            ties += 1

    win_rate = (wins + ties * 0.5) / iterations
    return round(win_rate * 100, 2)

# Streamlit UI
st.set_page_config(page_title="Calculadora de Póker Texas Hold'em")
st.title("🃏 Calculadora de Probabilidad de Ganar en Texas Hold'em")

hole_cards_input = st.text_input("Tus cartas (ej: Ah,Kd):")
flop_input = st.text_input("Cartas del Flop (ej: Qs,Jc,Th):")
turn_input = st.text_input("Carta del Turn (ej: 2d):")
river_input = st.text_input("Carta del River (ej: 9h):")

if st.button("Calcular Probabilidad"):
    try:
        hole_cards = [card.strip() for card in hole_cards_input.split(',') if card.strip()]
        flop = [card.strip() for card in flop_input.split(',') if card.strip()]
        turn = turn_input.strip() if turn_input else None
        river = river_input.strip() if river_input else None

        if len(hole_cards) != 2:
            st.error("Debes ingresar exactamente 2 cartas para tu mano.")
        elif len(flop) not in [0, 3]:
            st.error("Debes ingresar 0 o 3 cartas para el flop.")
        else:
            prob = calculate_win_probability(hole_cards, flop, turn, river)
            st.success(f"Probabilidad de ganar: {prob}%")
    except Exception as e:
        st.error(f"Error en la entrada: {str(e)}")
