#include "freqtable.h"
#include <stdlib.h>
#include <string.h>
#include "stringso.h"

t_freqtable_entry* freqtable_entry_create(char* lexeme);
t_freqtable_entry* freqtable_entry_create_as_error(char* lexeme, uint32_t line);

t_freqtable* freqtable_create(){
    t_freqtable* freqtable = malloc(sizeof(t_freqtable));
	t_list* elements = list_create();
	freqtable->elements = elements;
	return freqtable;
}

t_freqtable_entry* freqtable_entry_create(char* lexeme){
    t_freqtable_entry* new_entry = malloc(sizeof(t_freqtable_entry));
    new_entry->lexeme = string_duplicate(lexeme);
    new_entry->frequency = 1;
    return new_entry;
}

t_freqtable_entry* freqtable_entry_create_as_error(char* lexeme, uint32_t line){
    t_freqtable_entry* new_entry = malloc(sizeof(t_freqtable_entry));
    new_entry->lexeme = string_duplicate(lexeme);
    new_entry->frequency = line;
    return new_entry;
}

void freqtable_destroy_and_destroy_elements(t_freqtable* self){
    void _entry_destroyer(void* element){
        t_freqtable_entry* r_element = (t_freqtable_entry*)element;
        free(r_element->lexeme);
        free(r_element);
    }
    list_destroy_and_destroy_elements(self->elements, _entry_destroyer);
	free(self);
}

void freqtable_add(t_freqtable* self, char* lexeme){
    bool _is_same_string(void* element){
        t_freqtable_entry* r_element = (t_freqtable_entry*)element;
        bool result = !strcmp(r_element->lexeme, lexeme);
        return result;
    }
    t_freqtable_entry* entry = (t_freqtable_entry*) list_find(self->elements, _is_same_string);

    if (entry != NULL){
        entry->frequency += 1;
    }
    else{
        list_add(self->elements, (void*)freqtable_entry_create(lexeme));
    }
}

void freqtable_add_alpha(t_freqtable* self, char* lexeme){
    bool _is_smaller_alpha(void* element, void* element2){
        t_freqtable_entry* r_element = (t_freqtable_entry*)element;
        t_freqtable_entry* r_element2 = (t_freqtable_entry*)element;
        if(strcmp(r_element->lexeme, r_element2->lexeme) < 1) return true;
        else return false;
    }
    freqtable_add(self, lexeme);
    list_sort(self->elements, _is_smaller_alpha);
}

void freqtable_add_as_error(t_freqtable* self, char* lexeme, uint32_t line){
    list_add(self->elements, (void*)freqtable_entry_create_as_error(lexeme, line));
}