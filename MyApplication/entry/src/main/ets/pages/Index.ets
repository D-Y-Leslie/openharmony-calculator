@Entry
@Component
struct Index {
  // 显示完整的计算表达式，如 "2 × (3 + 5)"
  @State expression: string = '';
  // 显示计算结果，如 "= 16"
  @State resultDisplay: string = '0';
  // 标记计算是否刚完成
  private isFinished: boolean = false;

  // 按钮数据源（6行布局，涵盖括号功能）
  private readonly buttons: string[] = [
    'C', '(', ')', '⌫',  // 第一行：清除、括号、退格
    '%', '÷', '×', '1/x',// 第二行：百分比、运算符（增加倒数功能占位，或留空）
    '7', '8', '9', '-',  // 数字区
    '4', '5', '6', '+',
    '1', '2', '3', '=',  // = 号放这里或者底部
    '0', '.',            // 0 和 .
  ];

  // 优化后的布局：5行 x 4列 (更紧凑，符合习惯)
  // 行1: C   (   )   ⌫
  // 行2: 7   8   9   ÷
  // 行3: 4   5   6   ×
  // 行4: 1   2   3   -
  // 行5: 0   .   %   +
  // 底部: = (独立大按钮)
  // 下面代码采用 Grid 内部由 0-9 和运算符组成，= 号独立放置的设计，体验更好。

  build() {
    Column() {
      // --- 显示区域 ---
      Column() {
        // 算式显示
        Text(this.expression)
          .fontSize(30)
          .fontColor('#7c7c7c')
          .width('95%')
          .textAlign(TextAlign.End)
          .margin({ top: 40, bottom: 10 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 结果显示
        Text(this.resultDisplay)
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('95%')
          .textAlign(TextAlign.End)
          .maxLines(1)
      }
      .width('100%')
      .height('30%')
      .backgroundColor('#f7f9fc')
      .justifyContent(FlexAlign.End)
      .padding({ bottom: 20 })

      // --- 键盘区域 ---
      // 使用 Flex Wrap 或者 Grid 来布局
      // 这里使用 Grid，调整为标准的科学计算器布局
      Grid() {
        // 第一排
        this.GridBtn('C', '#d4d4d2', '#000')
        this.GridBtn('(', '#d4d4d2', '#000')
        this.GridBtn(')', '#d4d4d2', '#000')
        this.GridBtn('⌫', '#d4d4d2', '#000')

        // 第二排
        this.GridBtn('7')
        this.GridBtn('8')
        this.GridBtn('9')
        this.GridBtn('÷', '#ff9f0a', '#fff')

        // 第三排
        this.GridBtn('4')
        this.GridBtn('5')
        this.GridBtn('6')
        this.GridBtn('×', '#ff9f0a', '#fff')

        // 第四排
        this.GridBtn('1')
        this.GridBtn('2')
        this.GridBtn('3')
        this.GridBtn('-', '#ff9f0a', '#fff')

        // 第五排
        this.GridBtn('0')
        this.GridBtn('.')
        this.GridBtn('%') // 将百分号放在这里
        this.GridBtn('+', '#ff9f0a', '#fff')
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .padding(15)
      .width('100%')
      .height('55%') // 留出空间给等于号

      // 独立的等于号按钮，方便点击
      Button('=')
        .width('90%')
        .height(70)
        .type(ButtonType.Capsule) // 胶囊型
        .fontSize(35)
        .backgroundColor('#4a90e2')
        .fontColor(Color.White)
        .margin({ top: 5 })
        .shadow({ radius: 5, color: 'rgba(74, 144, 226, 0.4)', offsetY: 5 })
        .onClick(() => {
          this.handleCalculate();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fff')
  }

  // 封装按钮组件
  @Builder
  GridBtn(text: string, bgColor: string = '#fff', fontColor: string = '#333') {
    GridItem() {
      Button(text)
        .width(70)
        .height(70)
        .type(ButtonType.Circle)
        .fontSize(text === '⌫' ? 22 : 28) // 调整删除键字体大小
        .fontWeight(FontWeight.Medium)
        .backgroundColor(bgColor)
        .fontColor(fontColor)
        .shadow(bgColor === '#fff' ? { radius: 5, color: 'rgba(0,0,0,0.1)', offsetY: 2 } : { radius: 0 })
        .onClick(() => {
          this.handleInput(text);
        })
    }
  }

  // --- 逻辑处理 ---

  handleInput(val: string) {
    // 1. 清除
    if (val === 'C') {
      this.expression = '';
      this.resultDisplay = '0';
      this.isFinished = false;
      return;
    }

    // 2. 删除
    if (val === '⌫') {
      if (this.isFinished) {
        this.expression = '';
        this.isFinished = false;
      } else if (this.expression.length > 0) {
        this.expression = this.expression.slice(0, -1);
      }
      return;
    }

    // 3. 连续计算处理
    if (this.isFinished) {
      // 如果刚算完，输入的是运算符，则基于结果继续算
      if (['+', '-', '×', '÷', '%'].includes(val)) {
        this.expression = this.resultDisplay + val;
      } else {
        // 如果输入的是数字或括号，开始新计算
        this.expression = val;
      }
      this.isFinished = false;
      this.resultDisplay = '0'; // 重置显示结果
      return;
    }

    // 4. 普通输入
    this.expression += val;
  }

  // --- 核心计算引擎 (支持括号和优先级) ---
  handleCalculate() {
    if (this.expression.trim() === '') return;

    try {
      // 1. 预处理：将界面符号转换为数学符号
      let formula = this.expression
        .replace(/×/g, '*')
        .replace(/÷/g, '/')
        .replace(/%/g, '*0.01'); // 简单处理百分号：视为乘以 0.01

      // 2. 执行计算
      let result = this.solveExpression(formula);

      // 3. 格式化结果 (解决精度问题，如 0.30000000004)
      let finalRes = parseFloat(result.toFixed(8)).toString();

      this.resultDisplay = finalRes;
      this.isFinished = true;
    } catch (e) {
      this.resultDisplay = 'Error';
      this.isFinished = true;
    }
  }

  /**
   * 手写一个简单的表达式求值器 (双栈法)
   * 支持 + - * / ( )
   */
  solveExpression(formula: string): number {
    // 定义优先级
    const precedence: Record<string, number> = { '+': 1, '-': 1, '*': 2, '/': 2 };

    let numStack: number[] = [];
    let opStack: string[] = [];

    // 正则拆分：匹配 数字(包含小数) 或 运算符
    // 例如 "10.5+2*(3-1)" -> ["10.5", "+", "2", "*", "(", "3", "-", "1", ")"]
    let tokens = formula.match(/(\d+(\.\d+)?|[\+\-\*\/\(\)])/g);
    if (!tokens) return 0;

    const performOp = () => {
      let b = numStack.pop()!;
      let a = numStack.pop()!;
      let op = opStack.pop()!;
      switch (op) {
        case '+': numStack.push(a + b); break;
        case '-': numStack.push(a - b); break;
        case '*': numStack.push(a * b); break;
        case '/':
          if(b === 0) throw new Error("DivZero");
          numStack.push(a / b);
          break;
      }
    };

    for (let token of tokens) {
      if (!isNaN(Number(token))) {
        // 是数字
        numStack.push(Number(token));
      } else if (token === '(') {
        // 左括号入栈
        opStack.push(token);
      } else if (token === ')') {
        // 右括号：计算直到遇到左括号
        while (opStack.length > 0 && opStack[opStack.length - 1] !== '(') {
          performOp();
        }
        opStack.pop(); // 弹出 '('
      } else {
        // 是运算符：处理优先级
        while (
          opStack.length > 0 &&
            opStack[opStack.length - 1] !== '(' &&
            precedence[opStack[opStack.length - 1]] >= precedence[token]
        ) {
          performOp();
        }
        opStack.push(token);
      }
    }

    // 处理剩余的运算
    while (opStack.length > 0) {
      performOp();
    }

    return numStack[0] ?? 0;
  }
}