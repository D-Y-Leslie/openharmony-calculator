import { window } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State expression: string = ''
  @State result: string = '0'

  // 定义按钮布局
  private buttons: string[][] = [
    ['C', '÷', '×', 'DEL'],
    ['7', '8', '9', '-'],
    ['4', '5', '6', '+'],
    ['1', '2', '3', '='],
    ['%', '0', '.', '']
  ]

  build() {
    Column() {
      // 1. 显示区域
      Column() {
        Text(this.expression)
          .width('100%')
          .textAlign(TextAlign.End)
          .fontSize(24)
          .fontColor('#7f8c8d')
          .margin({ bottom: 10 })

        Text(this.result)
          .width('100%')
          .textAlign(TextAlign.End)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
      }
      .width('100%')
      .height('30%')
      .padding(20)
      .justifyContent(FlexAlign.End)
      .backgroundColor('#ecf0f1')

      // 2. 键盘区域
      Column() {
        ForEach(this.buttons, (row: string[]) => {
          Row() {
            ForEach(row, (btn: string) => {
              if (btn !== '') {
                Button(btn)
                  .type(ButtonType.Normal)
                  .borderRadius(12)
                  .backgroundColor(this.getBtnColor(btn))
                  .fontColor(this.getBtnTextColor(btn))
                  .fontSize(24)
                  .width('22%')
                  .height('80%')
                  .onClick(() => {
                    this.handleInput(btn)
                  })
                  .shadow({ radius: 5, color: '#bdc3c7', offsetX: 2, offsetY: 2 })
              } else {
                Blank().width('22%')
              }
            })
          }
          .width('100%')
          .height('18%')
          .justifyContent(FlexAlign.SpaceEvenly)
        })
      }
      .width('100%')
      .height('70%')
      .padding({ top: 20, bottom: 20 })
      .backgroundColor('#ffffff')
    }
    .height('100%')
    .width('100%')
  }

  getBtnColor(btn: string): string {
    if (['C', 'DEL'].includes(btn)) return '#e74c3c';
    if (['=', '+', '-', '×', '÷'].includes(btn)) return '#3498db';
    return '#f5f6fa';
  }

  getBtnTextColor(btn: string): string {
    if (['C', 'DEL', '=', '+', '-', '×', '÷'].includes(btn)) return '#ffffff';
    return '#2c3e50';
  }

  handleInput(val: string) {
    if (val === 'C') {
      this.expression = '';
      this.result = '0';
      return;
    }
    if (val === 'DEL') {
      this.expression = this.expression.slice(0, -1);
      return;
    }
    if (val === '=') {
      this.result = this.calculate(this.expression);
      return;
    }
    this.expression += val;
  }

  calculate(expression: string): string {
    let expr = expression.replace(/×/g, '*').replace(/÷/g, '/');
    if (!expr || expr.length === 0) return '0';
    if (['+', '-', '*', '/'].includes(expr.slice(-1))) return 'Error';

    try {
      let result = this.computeLogic(expr);
      return parseFloat(result.toPrecision(12)).toString();
    } catch (e) {
      return 'Error';
    }
  }

  computeLogic(expr: string): number {
    // 【关键修改】这里必须显式声明数组类型，不能用 any
    let tokens: (number | string)[] = [];
    let currentNum = "";

    for (let i = 0; i < expr.length; i++) {
      let char = expr[i];
      if (['+', '-', '*', '/'].includes(char)) {
        if (currentNum !== "") {
          tokens.push(parseFloat(currentNum));
          currentNum = "";
        }
        tokens.push(char);
      } else {
        currentNum += char;
      }
    }
    if (currentNum !== "") {
      tokens.push(parseFloat(currentNum));
    }

    let i = 0;
    while (i < tokens.length) {
      let operator = tokens[i];
      if (operator === '*' || operator === '/') {
        let prev = tokens[i - 1] as number;
        let next = tokens[i + 1] as number;
        let res = 0;
        if (operator === '*') res = prev * next;
        if (operator === '/') {
          if(next === 0) res = 0;
          else res = prev / next;
        }
        tokens.splice(i - 1, 3, res);
        i = i - 1;
      } else {
        i++;
      }
    }

    let finalResult = tokens[0] as number;
    for (let j = 1; j < tokens.length; j += 2) {
      let operator = tokens[j];
      let nextVal = tokens[j + 1] as number;
      if (operator === '+') finalResult += nextVal;
      if (operator === '-') finalResult -= nextVal;
    }
    return finalResult;
  }
}