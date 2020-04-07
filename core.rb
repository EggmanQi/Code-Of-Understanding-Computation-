# 定义规约: 输入的代码是否能进行规约, 可理解为代码能否进行求值,  demo 中 Number 类即不能求值
#def reducible?(expression)
#    case expression
#        when Number
#            false
#        when Add, Mutiply
#            true
#    end
#end

# 构造虚拟机: 代码和状态封装到一个类, 对表达式进行求值(小步规约) 
class Machine < Struct.new(:statement, :envirioment)
    def step
        self.statement, self.envirioment = statement.reduce(envirioment)
    end

    def run 
        while statement.reducible?
            puts "#{statement}, #{envirioment}"
            step
        end
            puts "#{statement}, #{envirioment}"
    end
end

# 定义基本类型
class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end
    def inspect
        "<<#{self}>>"
    end
    def reducible?
        false
    end
end

class Number < Struct.new(:value)
    def to_s
        value.to_s
    end
    def inspect
        "<<#{self}>>"
    end
    def reducible?
        false
    end
end

# 定义变量
class Variable < Struct.new(:name) 
    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(envirioment) 
        envirioment[name]
    end
end

# 定义操作符
class Add < Struct.new(:left,:right)
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(envirioment) 
        if left.reducible?
            Add.new(left.reduce(envirioment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(envirioment))
        else 
            Number.new(left.value + right.value)
        end
    end

end

class Mutiply < Struct.new(:left, :right)
    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(envirioment) 
        if left.reducible?
            Mutiply.new(left.reduce(envirioment), right)
        elsif right.reducible?
            Mutiply.new(left, right.reduce(envirioment))
        else 
            Number.new(left.value * right.value)
        end
    end
end

# 定义比较运算
class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end
    def inspect
        "<<#{self}>>"
    end
    def reducible?
        true
    end

    def reduce(envirioment) 
        if left.reducible?
            LessThan.new(left.reduce(envirioment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(envirioment))
        else 
            Boolean.new(left.value < right.value)
        end
    end
end

# 定义赋值
class Assign < Struct.new(:name , :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "#{self}"
    end

    def reducible?
        true
    end

    def reduce(envirioment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(envirioment)), envirioment]
        else
            [DoNothing.new, envirioment.merge({ name => expression})]
        end
    end
end

# 定义 if
class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} else #{alternative}}"
    end
    def inspect
        "#{self}"
    end

    def reducible?
        true
    end

    def reduce(envirioment)
        if condition.reducible?
            [If.new(condition.reduce(envirioment), consequence, alternative),  
            envirioment]
        else
            case condition
                when Boolean.new(true)
                    [consequence, envirioment]
                when Boolean.new(false)
                    [alternative, envirioment]
            end
        end
    end
end

# 定义循环
class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) {#{body}}"
    end

    def inspect
        "#{self}"
    end

    def reducible?
        true
    end

    def reduce(envirioment)
        [If.new(condition, 
                Sequence.new(body, self), DoNothing.new), 
                envirioment]
    end
end

# 定义序列
class Sequence < Struct.new(:first, :second) 
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "#{self}"
    end

    def reducible?
        true
    end

    def reduce(envirioment)
        case first
        when DoNothing.new
            [second, envirioment]
        else 
            reduce_first, reduce_envirioment = first.reduce(envirioment)
            [Sequence.new(reduce_first, second), reduce_envirioment]
        end
    end
end

# 定义环境: 表示规约已经结束, 环境改变为 Do-nothing
class DoNothing
    def to_s
        'do-nothing'
    end

    def inspect
        "#{self}"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
end



# 抽象机器, 由一个初始表达式和环境开始, 每次小步规约都用当前表达式和环境生成一个新的表达式
#Machine.new(
#   Add.new(Variable.new(:x), Variable.new(:y)),
#   {x: Number.new(3), y: Number.new(5)} 
#).run

#Machine.new(
#    Assign.new(:x, Add.new(Variable.new(:x), Number.new(5))),
#    { x: Number.new(2)}
#).run

#Machine.new(
#    If.new(
#        Variable.new(:x),
#        Assign.new(:y, Number.new(1)),
#        Assign.new(:y, Number.new(2))
#    ),
#    { x: Boolean.new(true)}
#).run


#Machine.new(
#    If.new(
#        Variable.new(:x),
#        Assign.new(:y, Number.new(3)),
#        DoNothing.new
#    ),
#    { x: Boolean.new(false)}
#).run

puts "  "

#Machine.new(
#    Sequence.new(
#        Assign.new(:x, Add.new(Number.new(1), Number.new(3))),
#        Assign.new(:y, Mutiply.new(Variable.new(:x), Number.new(3)))
#    ),
#    {}
#).run

Machine.new(
    While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Mutiply.new(Variable.new(:x), Number.new(3)))
    ),
    { x: Number.new(1)}
).run



