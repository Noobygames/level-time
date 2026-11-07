package main

import (
	"fmt"
	"strconv"
	"strings"
)

// Liest eine globale Variable aus einer SavedVariables-Datei des Clients ("Name = { ... }"). Der Client schreibt
// nur Tabellen-Literale mit ["Schlüssel"] = Wert, [Zahl] = Wert und Werten ohne Schlüssel (mit "-- [n]"-Kommentar),
// dazu Strings, Zahlen, true/false/nil. Ein kleiner Parser genügt dafür, ohne Lua auszuführen.
// Tabellen werden zu map[string]any (Zahlenschlüssel als Text), Zahlen zu float64.

// ParseVariable sucht "name = " am Zeilenanfang und liest den Wert dahinter (nil, wenn die Variable fehlt).
func ParseVariable(content, name string) (any, error) {
	start := -1
	prefix := name + " = "
	for offset := 0; offset < len(content); {
		end := strings.IndexByte(content[offset:], '\n')
		line := content[offset:]
		if end >= 0 {
			line = content[offset : offset+end]
		}
		if strings.HasPrefix(line, prefix) {
			start = offset + len(prefix)
			break
		}
		if end < 0 {
			break
		}
		offset += end + 1
	}
	if start < 0 {
		return nil, nil
	}
	p := &luaParser{text: content, pos: start}
	return p.value()
}

type luaParser struct {
	text string
	pos  int
}

func (p *luaParser) fail(format string, args ...any) error {
	return fmt.Errorf("SavedVariables bei Zeichen %d: %s", p.pos, fmt.Sprintf(format, args...))
}

// Leerraum und Kommentare ("-- [1]") überspringen
func (p *luaParser) skip() {
	for p.pos < len(p.text) {
		c := p.text[p.pos]
		switch {
		case c == ' ' || c == '\t' || c == '\r' || c == '\n':
			p.pos++
		case strings.HasPrefix(p.text[p.pos:], "--"):
			end := strings.IndexByte(p.text[p.pos:], '\n')
			if end < 0 {
				p.pos = len(p.text)
			} else {
				p.pos += end + 1
			}
		default:
			return
		}
	}
}

func (p *luaParser) value() (any, error) {
	p.skip()
	if p.pos >= len(p.text) {
		return nil, p.fail("Wert fehlt")
	}
	switch c := p.text[p.pos]; {
	case c == '{':
		return p.table()
	case c == '"':
		return p.str()
	case strings.HasPrefix(p.text[p.pos:], "true"):
		p.pos += 4
		return true, nil
	case strings.HasPrefix(p.text[p.pos:], "false"):
		p.pos += 5
		return false, nil
	case strings.HasPrefix(p.text[p.pos:], "nil"):
		p.pos += 3
		return nil, nil
	default:
		return p.number()
	}
}

func (p *luaParser) number() (any, error) {
	start := p.pos
	for p.pos < len(p.text) && strings.IndexByte("+-0123456789.eExXabcdefABCDEFinf", p.text[p.pos]) >= 0 {
		p.pos++
	}
	text := p.text[start:p.pos]
	value, err := strconv.ParseFloat(text, 64)
	if err != nil {
		return nil, p.fail("keine Zahl: %q", text)
	}
	return value, nil
}

// Lua-String mit den Escapes, die der Client schreibt (\" \\ \n \r \t und \ddd)
func (p *luaParser) str() (string, error) {
	p.pos++ // "
	var b strings.Builder
	for p.pos < len(p.text) {
		c := p.text[p.pos]
		switch c {
		case '"':
			p.pos++
			return b.String(), nil
		case '\\':
			p.pos++
			if p.pos >= len(p.text) {
				return "", p.fail("String endet mit \\")
			}
			e := p.text[p.pos]
			switch e {
			case 'n':
				b.WriteByte('\n')
			case 'r':
				b.WriteByte('\r')
			case 't':
				b.WriteByte('\t')
			case '\n':
				b.WriteByte('\n')
			default:
				if e >= '0' && e <= '9' {
					end := p.pos
					for end < len(p.text) && end < p.pos+3 && p.text[end] >= '0' && p.text[end] <= '9' {
						end++
					}
					code, _ := strconv.Atoi(p.text[p.pos:end])
					b.WriteByte(byte(code))
					p.pos = end
					continue
				}
				b.WriteByte(e)
			}
			p.pos++
		default:
			b.WriteByte(c)
			p.pos++
		}
	}
	return "", p.fail("String ohne Ende")
}

func (p *luaParser) table() (map[string]any, error) {
	p.pos++ // {
	result := map[string]any{}
	next := 1
	for {
		p.skip()
		if p.pos >= len(p.text) {
			return nil, p.fail("Tabelle ohne Ende")
		}
		if p.text[p.pos] == '}' {
			p.pos++
			return result, nil
		}
		var key string
		if p.text[p.pos] == '[' {
			p.pos++
			p.skip()
			raw, err := p.value()
			if err != nil {
				return nil, err
			}
			key = keyText(raw)
			p.skip()
			if !strings.HasPrefix(p.text[p.pos:], "]") {
				return nil, p.fail("] fehlt")
			}
			p.pos++
			p.skip()
			if !strings.HasPrefix(p.text[p.pos:], "=") {
				return nil, p.fail("= fehlt")
			}
			p.pos++
		} else {
			key = strconv.Itoa(next)
			next++
		}
		value, err := p.value()
		if err != nil {
			return nil, err
		}
		result[key] = value
		p.skip()
		if p.pos < len(p.text) && (p.text[p.pos] == ',' || p.text[p.pos] == ';') {
			p.pos++
		}
	}
}

func keyText(raw any) string {
	switch v := raw.(type) {
	case string:
		return v
	case float64:
		return strconv.FormatFloat(v, 'f', -1, 64)
	default:
		return fmt.Sprint(v)
	}
}
